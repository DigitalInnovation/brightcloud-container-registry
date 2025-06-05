# Core Configuration
variable "registry_name" {
  type        = string
  description = "Name of the Azure Container Registry"
}

variable "registry_id" {
  type        = string
  description = "Resource ID of the Azure Container Registry"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region for monitoring resources"
}

# Log Analytics Configuration
variable "create_log_analytics" {
  type        = bool
  description = "Whether to create a new Log Analytics workspace"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Existing Log Analytics workspace ID (required if create_log_analytics is false)"
  default     = null
}

variable "log_analytics_sku" {
  type        = string
  description = "SKU for Log Analytics workspace"
  default     = "PerGB2018"
  
  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.log_analytics_sku)
    error_message = "Invalid Log Analytics SKU. Must be one of: Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018."
  }
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain logs in Log Analytics"
  default     = 90
  
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

# Application Insights Configuration
variable "create_application_insights" {
  type        = bool
  description = "Whether to create Application Insights for monitoring"
  default     = true
}

# Notification Configuration
variable "notification_email_addresses" {
  type        = list(string)
  description = "List of email addresses for alert notifications"
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.notification_email_addresses : can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "notification_webhooks" {
  type = list(object({
    uri = string
  }))
  description = "List of webhook configurations for alert notifications"
  default     = []
}

variable "notification_sms_numbers" {
  type = list(object({
    country_code = string
    phone_number = string
  }))
  description = "List of SMS numbers for alert notifications"
  default     = []
}

variable "alert_manager" {
  type        = string
  description = "Alert manager system (e.g., PagerDuty, OpsGenie, etc.)"
  default     = "Azure Monitor"
}

# Storage Alerts
variable "enable_storage_alerts" {
  type        = bool
  description = "Enable storage quota alerts"
  default     = true
}

variable "storage_threshold_bytes" {
  type        = number
  description = "Storage threshold in bytes for alerts"
  default     = 85899345920 # 80 GB
}

variable "storage_alert_severity" {
  type        = string
  description = "Severity level for storage alerts"
  default     = "warning"
  
  validation {
    condition     = contains(["critical", "error", "warning", "info", "verbose"], var.storage_alert_severity)
    error_message = "Alert severity must be one of: critical, error, warning, info, verbose."
  }
}

# Security Alerts
variable "enable_security_alerts" {
  type        = bool
  description = "Enable security-related alerts"
  default     = true
}

variable "failed_login_threshold" {
  type        = number
  description = "Number of failed login attempts to trigger alert"
  default     = 5
}

variable "security_alert_severity" {
  type        = string
  description = "Severity level for security alerts"
  default     = "error"
  
  validation {
    condition     = contains(["critical", "error", "warning", "info", "verbose"], var.security_alert_severity)
    error_message = "Alert severity must be one of: critical, error, warning, info, verbose."
  }
}

# Performance Alerts
variable "enable_performance_alerts" {
  type        = bool
  description = "Enable performance-related alerts"
  default     = true
}

variable "pull_rate_threshold" {
  type        = number
  description = "Pull rate threshold for performance alerts"
  default     = 1000
}

variable "performance_alert_severity" {
  type        = string
  description = "Severity level for performance alerts"
  default     = "warning"
  
  validation {
    condition     = contains(["critical", "error", "warning", "info", "verbose"], var.performance_alert_severity)
    error_message = "Alert severity must be one of: critical, error, warning, info, verbose."
  }
}

# Availability Alerts
variable "enable_availability_alerts" {
  type        = bool
  description = "Enable availability alerts"
  default     = true
}

# Dashboard Configuration
variable "create_monitoring_dashboard" {
  type        = bool
  description = "Create monitoring dashboard in Azure Workbooks"
  default     = true
}

# Custom Metrics Configuration
variable "custom_metrics" {
  type = list(object({
    name      = string
    namespace = string
    query     = string
    frequency = string
    enabled   = bool
  }))
  description = "List of custom metrics to create"
  default     = []
}

# Alert Suppressions
variable "alert_suppressions" {
  type = list(object({
    name               = string
    description        = string
    suppression_type   = string
    start_time         = string
    end_time           = string
    recurrence_pattern = optional(string)
  }))
  description = "List of alert suppressions for maintenance windows"
  default     = []
}

# Integration Configuration
variable "integration_config" {
  type = object({
    enable_azure_security_center = optional(bool, false)
    enable_sentinel_integration  = optional(bool, false)
    enable_grafana_integration   = optional(bool, false)
    grafana_workspace_id         = optional(string)
  })
  description = "Configuration for external integrations"
  default     = {}
}

# Cost Management
variable "enable_cost_alerts" {
  type        = bool
  description = "Enable cost-related alerts"
  default     = false
}

variable "monthly_cost_threshold" {
  type        = number
  description = "Monthly cost threshold for cost alerts (in USD)"
  default     = 100
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to monitoring resources"
  default     = {}
  
  validation {
    condition = alltrue([
      for key, value in var.tags : length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be 128 characters or less, and values must be 256 characters or less."
  }
}