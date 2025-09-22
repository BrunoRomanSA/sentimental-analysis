
resource "aws_cloudwatch_metric_alarm" "accuracy_alarm" {
  alarm_name          = "MovieReviewModel-AccuracyAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 0.84
  treat_missing_data  = "notBreaching"

  # Período: 1 semana em segundos (7 dias * 24h * 3600s)
  period = 604800
  statistic = "Average"

  # Métrica calculada (Metric Math)
  metric_query {
    id          = "correct"
    metric {
      namespace   = "MovieReviewModel"
      metric_name = "CorrectPredictions"
      stat        = "Sum"
      period      = 604800
    }
  }

  metric_query {
    id          = "total"
    metric {
      namespace   = "MovieReviewModel"
      metric_name = "PredictionCount"
      stat        = "Sum"
      period      = 604800
    }
  }

  # Calcula acurácia
  metric_query {
    id          = "accuracy"
    expression  = "correct / total"
    label       = "Accuracy"
    return_data = true
  }

  metric_query {
    id          = "validAccuracy"
    expression  = "IF(total >= 500, accuracy, 1)"
    label       = "ValidAccuracy"
    return_data = true
  }

  alarm_description = "Dispara se a acurácia cair abaixo de 84% em 1 semana com pelo menos 500 amostras"

  # Condição para só avaliar quando tiver no mínimo 500 amostras
  insufficient_data_actions = []
}