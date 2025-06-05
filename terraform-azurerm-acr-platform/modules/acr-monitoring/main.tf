locals {
  # Standard log categories for ACR
  acr_log_categories = [
    "ContainerRegistryRepositoryEvents",
    "ContainerRegistryLoginEvents"
  ]
  
  # Standard metric categories for ACR
  acr_metric_categories = [
    "AllMetrics"
  ]

  # Alert severity mapping
  alert_severities = {
    "critical" = 0
    "error"    = 1
    "warning"  = 2
    "info"     = 3
    "verbose"  = 4
  }

  # Common tags for monitoring resources
  monitoring_tags = merge(
    var.tags,
    {
      "Component"    = "Monitoring"
      "MonitoredBy"  = "BrightCloud-ACR-Platform"
      "AlertManager" = var.alert_manager
    }
  )
}

data "azurerm_client_config" "current" {}

# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "acr" {
  count               = var.create_log_analytics ? 1 : 0
  name                = "${var.registry_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  tags = local.monitoring_tags

  lifecycle {
    prevent_destroy = true
  }
}

# Application Insights for application performance monitoring
resource "azurerm_application_insights" "acr" {
  count               = var.create_application_insights ? 1 : 0
  name                = "${var.registry_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].id : var.log_analytics_workspace_id
  application_type    = "other"

  tags = local.monitoring_tags
}

# Diagnostic settings for Container Registry
resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                           = "${var.registry_name}-diagnostics"
  target_resource_id             = var.registry_id
  log_analytics_workspace_id     = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].id : var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  # Enable all relevant log categories
  dynamic "enabled_log" {
    for_each = local.acr_log_categories
    content {
      category = enabled_log.value
    }
  }

  # Enable metrics
  dynamic "metric" {
    for_each = local.acr_metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type
    ]
  }
}

# Action Group for alert notifications
resource "azurerm_monitor_action_group" "acr" {
  count               = length(var.notification_email_addresses) > 0 || length(var.notification_webhooks) > 0 ? 1 : 0
  name                = "${var.registry_name}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = substr("${var.registry_name}acr", 0, 12)

  # Email notifications
  dynamic "email_receiver" {
    for_each = var.notification_email_addresses
    content {
      name                    = "email-${email_receiver.key}"
      email_address          = email_receiver.value
      use_common_alert_schema = true
    }
  }

  # Webhook notifications
  dynamic "webhook_receiver" {
    for_each = var.notification_webhooks
    content {
      name                    = "webhook-${webhook_receiver.key}"
      service_uri            = webhook_receiver.value.uri
      use_common_alert_schema = true
    }
  }

  # SMS notifications
  dynamic "sms_receiver" {
    for_each = var.notification_sms_numbers
    content {
      name         = "sms-${sms_receiver.key}"
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  tags = local.monitoring_tags
}

# Storage quota alert
resource "azurerm_monitor_metric_alert" "storage_quota" {
  count               = var.enable_storage_alerts ? 1 : 0
  name                = "${var.registry_name}-storage-quota-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.registry_id]
  description         = "Alert when ACR storage usage exceeds threshold"
  severity            = local.alert_severities[var.storage_alert_severity]
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerRegistry/registries"
    metric_name      = "StorageUsed"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.storage_threshold_bytes
  }

  dynamic "action" {
    for_each = length(var.notification_email_addresses) > 0 || length(var.notification_webhooks) > 0 ? [1] : []
    content {
      action_group_id = azurerm_monitor_action_group.acr[0].id
    }
  }

  tags = local.monitoring_tags
}

# Failed login attempts alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_logins" {
  count               = var.enable_security_alerts ? 1 : 0
  name                = "${var.registry_name}-failed-logins-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes              = [var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].id : var.log_analytics_workspace_id]
  severity            = local.alert_severities[var.security_alert_severity]
  
  criteria {
    query                   = <<-QUERY
      ContainerRegistryLoginEvents
      | where TimeGenerated > ago(15m)
      | where ResultType == "Failed"
      | summarize FailedAttempts = count() by bin(TimeGenerated, 5m), Identity
      | where FailedAttempts >= ${var.failed_login_threshold}
    QUERY
    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  dynamic "action" {
    for_each = length(var.notification_email_addresses) > 0 || length(var.notification_webhooks) > 0 ? [1] : []
    content {
      action_groups = [azurerm_monitor_action_group.acr[0].id]
    }
  }

  tags = local.monitoring_tags
}

# High pull rate alert
resource "azurerm_monitor_metric_alert" "high_pull_rate" {
  count               = var.enable_performance_alerts ? 1 : 0
  name                = "${var.registry_name}-high-pull-rate-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.registry_id]
  description         = "Alert when pull rate exceeds normal threshold"
  severity            = local.alert_severities[var.performance_alert_severity]
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerRegistry/registries"
    metric_name      = "TotalPullCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.pull_rate_threshold
  }

  dynamic "action" {
    for_each = length(var.notification_email_addresses) > 0 || length(var.notification_webhooks) > 0 ? [1] : []
    content {
      action_group_id = azurerm_monitor_action_group.acr[0].id
    }
  }

  tags = local.monitoring_tags
}

# Registry availability alert
resource "azurerm_monitor_metric_alert" "registry_availability" {
  count               = var.enable_availability_alerts ? 1 : 0
  name                = "${var.registry_name}-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.registry_id]
  description         = "Alert when registry availability drops"
  severity            = local.alert_severities["critical"]
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerRegistry/registries"
    metric_name      = "AgentPoolCPUTime"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  dynamic "action" {
    for_each = length(var.notification_email_addresses) > 0 || length(var.notification_webhooks) > 0 ? [1] : []
    content {
      action_group_id = azurerm_monitor_action_group.acr[0].id
    }
  }

  tags = local.monitoring_tags
}

# Workbook for ACR monitoring dashboard
resource "azurerm_application_insights_workbook" "acr_dashboard" {
  count               = var.create_monitoring_dashboard ? 1 : 0
  name                = "${var.registry_name}-monitoring-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "ACR Monitoring Dashboard - ${var.registry_name}"
  
  data_json = jsonencode({
    "version": "Notebook/1.0",
    "items": [
      {
        "type": 1,
        "content": {
          "json": "# Azure Container Registry Monitoring\n\n## ${var.registry_name}\n\nThis dashboard provides comprehensive monitoring for your Azure Container Registry instance."
        },
        "name": "text - title"
      },
      {
        "type": 10,
        "content": {
          "chartId": "workbook-storage-usage",
          "version": "MetricsItem/2.0",
          "size": 0,
          "chartType": 2,
          "resourceType": "Microsoft.ContainerRegistry/registries",
          "metricScope": 0,
          "resourceIds": [var.registry_id],
          "timeContext": {
            "durationMs": 86400000,
            "endTime": null,
            "createdTime": "2023-01-01T00:00:00.000Z",
            "isInitialTime": false,
            "grain": 1,
            "useDashboardTimeRange": false
          },
          "metrics": [
            {
              "namespace": "Microsoft.ContainerRegistry/registries",
              "metric": "Microsoft.ContainerRegistry/registries--StorageUsed",
              "aggregation": {
                "aggregationType": 4,
                "primaryAggregationType": 4
              },
              "splitBy": null
            }
          ],
          "title": "Storage Usage",
          "gridSettings": {
            "rowLimit": 10000
          }
        },
        "name": "metric - storage"
      },
      {
        "type": 10,
        "content": {
          "chartId": "workbook-pull-push-counts",
          "version": "MetricsItem/2.0",
          "size": 0,
          "chartType": 2,
          "resourceType": "Microsoft.ContainerRegistry/registries",
          "metricScope": 0,
          "resourceIds": [var.registry_id],
          "timeContext": {
            "durationMs": 86400000
          },
          "metrics": [
            {
              "namespace": "Microsoft.ContainerRegistry/registries",
              "metric": "Microsoft.ContainerRegistry/registries--TotalPullCount",
              "aggregation": {
                "aggregationType": 1
              }
            },
            {
              "namespace": "Microsoft.ContainerRegistry/registries",
              "metric": "Microsoft.ContainerRegistry/registries--TotalPushCount", 
              "aggregation": {
                "aggregationType": 1
              }
            }
          ],
          "title": "Pull/Push Activity",
          "gridSettings": {
            "rowLimit": 10000
          }
        },
        "name": "metric - activity"
      }
    ],
    "styleSettings": {},
    "fallbackResourceIds": []
  })

  tags = local.monitoring_tags
}

# Log queries for common monitoring scenarios
resource "azurerm_log_analytics_saved_search" "failed_authentication" {
  count                       = var.create_log_analytics ? 1 : 0
  name                        = "ACR-Failed-Authentication"
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.acr[0].id
  category                    = "Security"
  display_name                = "ACR Failed Authentication Attempts"
  
  query = <<-QUERY
    ContainerRegistryLoginEvents
    | where TimeGenerated > ago(24h)
    | where ResultType == "Failed"
    | summarize FailedAttempts = count() by Identity, bin(TimeGenerated, 1h)
    | order by TimeGenerated desc
  QUERY
}

resource "azurerm_log_analytics_saved_search" "repository_activity" {
  count                       = var.create_log_analytics ? 1 : 0
  name                        = "ACR-Repository-Activity"
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.acr[0].id
  category                    = "Usage"
  display_name                = "ACR Repository Activity"
  
  query = <<-QUERY
    ContainerRegistryRepositoryEvents
    | where TimeGenerated > ago(24h)
    | summarize Events = count() by Repository, EventName, bin(TimeGenerated, 1h)
    | order by TimeGenerated desc
  QUERY
}

resource "azurerm_log_analytics_saved_search" "top_repositories" {
  count                       = var.create_log_analytics ? 1 : 0
  name                        = "ACR-Top-Repositories"
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.acr[0].id
  category                    = "Usage"
  display_name                = "ACR Top Active Repositories"
  
  query = <<-QUERY
    ContainerRegistryRepositoryEvents
    | where TimeGenerated > ago(7d)
    | where EventName == "Pull"
    | summarize PullCount = count() by Repository
    | top 10 by PullCount desc
  QUERY
}