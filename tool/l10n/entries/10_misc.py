e('currentCard','atual','current','actual')
e('widgetDate',
  "=> '${const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'][d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'",
  "=> '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]}, ${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'",
  "=> '${const ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'][d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'",
  'DateTime d')
