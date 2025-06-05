# Log Analytics Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].id : var.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].name : null
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics workspace"
  value       = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].primary_shared_key : null
  sensitive   = true
}

output "log_analytics_workspace_location" {
  description = "Location of the Log Analytics workspace"
  value       = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].location : null
}

# Application Insights Outputs
output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = var.create_application_insights ? azurerm_application_insights.acr[0].id : null
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = var.create_application_insights ? azurerm_application_insights.acr[0].name : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.acr[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.acr[0].connection_string : null
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID for Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.acr[0].app_id : null
}

# Monitoring Configuration Outputs
output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.acr.id
}

output "diagnostic_setting_name" {
  description = "Name of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.acr.name
}

# Action Group Outputs
output "action_group_id" {
  description = "ID of the action group for alerts"
  value       = length(azurerm_monitor_action_group.acr) > 0 ? azurerm_monitor_action_group.acr[0].id : null
}

output "action_group_name" {
  description = "Name of the action group"
  value       = length(azurerm_monitor_action_group.acr) > 0 ? azurerm_monitor_action_group.acr[0].name : null
}

output "action_group_short_name" {
  description = "Short name of the action group"
  value       = length(azurerm_monitor_action_group.acr) > 0 ? azurerm_monitor_action_group.acr[0].short_name : null
}

# Alert Outputs
output "storage_alert_id" {
  description = "ID of the storage quota alert"
  value       = var.enable_storage_alerts ? azurerm_monitor_metric_alert.storage_quota[0].id : null
}

output "failed_login_alert_id" {
  description = "ID of the failed login alert"
  value       = var.enable_security_alerts ? azurerm_monitor_scheduled_query_rules_alert_v2.failed_logins[0].id : null
}

output "pull_rate_alert_id" {
  description = "ID of the high pull rate alert"
  value       = var.enable_performance_alerts ? azurerm_monitor_metric_alert.high_pull_rate[0].id : null
}

output "availability_alert_id" {
  description = "ID of the registry availability alert"
  value       = var.enable_availability_alerts ? azurerm_monitor_metric_alert.registry_availability[0].id : null
}

# Dashboard Outputs
output "monitoring_dashboard_id" {
  description = "ID of the monitoring dashboard"
  value       = var.create_monitoring_dashboard ? azurerm_application_insights_workbook.acr_dashboard[0].id : null
}

output "monitoring_dashboard_name" {
  description = "Name of the monitoring dashboard"
  value       = var.create_monitoring_dashboard ? azurerm_application_insights_workbook.acr_dashboard[0].display_name : null
}

# Saved Searches Outputs
output "saved_search_ids" {
  description = "IDs of saved log searches"
  value = var.create_log_analytics ? {
    failed_authentication = azurerm_log_analytics_saved_search.failed_authentication[0].id
    repository_activity   = azurerm_log_analytics_saved_search.repository_activity[0].id
    top_repositories     = azurerm_log_analytics_saved_search.top_repositories[0].id
  } : {}
}

# Monitoring Configuration Summary
output "monitoring_configuration" {
  description = "Summary of monitoring configuration"
  value = {
    log_analytics_enabled     = var.create_log_analytics
    application_insights_enabled = var.create_application_insights
    storage_alerts_enabled    = var.enable_storage_alerts
    security_alerts_enabled   = var.enable_security_alerts
    performance_alerts_enabled = var.enable_performance_alerts
    availability_alerts_enabled = var.enable_availability_alerts
    dashboard_enabled         = var.create_monitoring_dashboard
    notification_channels     = {
      email_count   = length(var.notification_email_addresses)
      webhook_count = length(var.notification_webhooks)
      sms_count     = length(var.notification_sms_numbers)
    }
    log_retention_days        = var.log_retention_days
    alert_thresholds         = {
      storage_bytes     = var.storage_threshold_bytes
      failed_logins     = var.failed_login_threshold
      pull_rate         = var.pull_rate_threshold
    }
  }
}

# Integration Endpoints
output "monitoring_endpoints" {
  description = "Monitoring integration endpoints"
  value = {
    log_analytics_workspace_id = var.create_log_analytics ? azurerm_log_analytics_workspace.acr[0].id : var.log_analytics_workspace_id
    application_insights_key   = var.create_application_insights ? azurerm_application_insights.acr[0].instrumentation_key : null
    action_group_webhook       = length(azurerm_monitor_action_group.acr) > 0 ? azurerm_monitor_action_group.acr[0].webhook_receiver : []
  }
  sensitive = true
}

# Query Examples for Common Scenarios
output "query_examples" {
  description = "Example queries for common monitoring scenarios"
  value = {
    failed_authentication_query = "ContainerRegistryLoginEvents | where TimeGenerated > ago(24h) | where ResultType == 'Failed' | summarize FailedAttempts = count() by Identity, bin(TimeGenerated, 1h)"
    repository_activity_query   = "ContainerRegistryRepositoryEvents | where TimeGenerated > ago(24h) | summarize Events = count() by Repository, EventName, bin(TimeGenerated, 1h)"
    top_repositories_query      = "ContainerRegistryRepositoryEvents | where TimeGenerated > ago(7d) | where EventName == 'Pull' | summarize PullCount = count() by Repository | top 10 by PullCount desc"
    storage_usage_query         = "AzureMetrics | where ResourceProvider == 'MICROSOFT.CONTAINERREGISTRY' | where MetricName == 'StorageUsed' | summarize avg(Average) by bin(TimeGenerated, 1h)"
    pull_push_activity_query    = "AzureMetrics | where ResourceProvider == 'MICROSOFT.CONTAINERREGISTRY' | where MetricName in ('TotalPullCount', 'TotalPushCount') | summarize sum(Total) by MetricName, bin(TimeGenerated, 1h)"
  }
}

# Alert URLs for Quick Access
output "alert_urls" {
  description = "Direct URLs to alert configurations in Azure Portal"
  value = var.enable_storage_alerts || var.enable_security_alerts || var.enable_performance_alerts || var.enable_availability_alerts ? {
    action_group_url = length(azurerm_monitor_action_group.acr) > 0 ? "https://portal.azure.com/#@/resource${azurerm_monitor_action_group.acr[0].id}" : null
    storage_alert_url = var.enable_storage_alerts ? "https://portal.azure.com/#@/resource${azurerm_monitor_metric_alert.storage_quota[0].id}" : null
    failed_login_alert_url = var.enable_security_alerts ? "https://portal.azure.com/#@/resource${azurerm_monitor_scheduled_query_rules_alert_v2.failed_logins[0].id}" : null
    pull_rate_alert_url = var.enable_performance_alerts ? "https://portal.azure.com/#@/resource${azurerm_monitor_metric_alert.high_pull_rate[0].id}" : null
    availability_alert_url = var.enable_availability_alerts ? "https://portal.azure.com/#@/resource${azurerm_monitor_metric_alert.registry_availability[0].id}" : null
  } : {}
}

# Monitoring Health Status
output "monitoring_health" {
  description = "Health status of monitoring components"
  value = {
    log_analytics_status = var.create_log_analytics ? "active" : "external"
    application_insights_status = var.create_application_insights ? "active" : "disabled"
    alerting_status = length(azurerm_monitor_action_group.acr) > 0 ? "configured" : "not_configured"
    dashboard_status = var.create_monitoring_dashboard ? "active" : "disabled"
    total_alerts_configured = (var.enable_storage_alerts ? 1 : 0) + 
                              (var.enable_security_alerts ? 1 : 0) + 
                              (var.enable_performance_alerts ? 1 : 0) + 
                              (var.enable_availability_alerts ? 1 : 0)
  }
}