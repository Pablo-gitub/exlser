enum AggregationType {
  count,
  sum,
  avg,
  min,
  max;

  String get sqlFunction => switch (this) {
        AggregationType.count => 'COUNT',
        AggregationType.sum => 'SUM',
        AggregationType.avg => 'AVG',
        AggregationType.min => 'MIN',
        AggregationType.max => 'MAX',
      };
}
