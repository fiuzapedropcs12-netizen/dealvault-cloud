# El budget se creó a mano desde la consola (para sumar créditos del onboarding).
# Se importa al state UNA vez con:
#   tofu import aws_budgets_budget.monthly <ACCOUNT_ID>:dealvault-monthly
# Desde ahí queda gestionado como código.

resource "aws_budgets_budget" "monthly" {
  name         = var.budget_name
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  billing_view_arn = "arn:aws:billing::${data.aws_caller_identity.current.account_id}:billingview/primary"
  metrics          = ["UnblendedCost"]

  # Excluye créditos y reembolsos: así el budget mide el consumo real y
  # avisa aunque los créditos del free plan lo estén cubriendo.
  filter_expression {
    not {
      dimensions {
        key    = "RECORD_TYPE"
        values = ["Credit", "Refund"]
      }
    }
  }

  # Aviso cuando el gasto real supera el 80%.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  # Aviso cuando el pronóstico del mes supera el 100%.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}