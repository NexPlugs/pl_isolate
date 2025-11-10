/// Priority of the task
enum TaskQueuePriority {
  low(level: 0),
  medium(level: 1),
  high(level: 2);

  final int level;
  const TaskQueuePriority({required this.level});
}
