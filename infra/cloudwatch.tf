resource "aws_cloudwatch_metric_alarm" "accuracy_alarm" {
  alarm_name          = "MovieReviewModel-AccuracyAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 0.84
  treat_missing_data  = "notBreaching"

  alarm_description = "Dispara se a acurácia cair abaixo de 84% em 1 semana com pelo menos 500 amostras"
  alarm_actions     = [aws_sns_topic.ml_model_alerts.arn]

  # Query 1: somatório de acertos
  metric_query {
    id = "correct"
    metric {
      namespace   = "MovieReviewModel"
      metric_name = "CorrectPredictions"
      stat        = "Sum"
      period      = 604800 # 1 semana
    }
  }

  # Query 2: somatório de previsões
  metric_query {
    id = "total"
    metric {
      namespace   = "MovieReviewModel"
      metric_name = "PredictionCount"
      stat        = "Sum"
      period      = 604800 # 1 semana
    }
  }

  # Query 3: calcula acurácia
  metric_query {
    id          = "accuracy"
    expression  = "correct / total"
    label       = "Accuracy"
    return_data = false
  }

  # Query 4: só considera válido se houver pelo menos 500 amostras
  metric_query {
    id          = "validAccuracy"
    expression  = "IF(total >= 500, accuracy, 1)"
    label       = "ValidAccuracy"
    return_data = true
  }


}