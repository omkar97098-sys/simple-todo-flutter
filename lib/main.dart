import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

// ============================================================
// APP
// ============================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Tasks',

      themeMode: isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      // ======================================================
      // LIGHT THEME
      // ======================================================

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),

        scaffoldBackgroundColor:
            const Color(0xFFF7F8FC),
      ),

      // ======================================================
      // DARK THEME
      // ======================================================

      darkTheme: ThemeData(
        useMaterial3: true,

        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),

      home: TodoPage(
        isDarkMode: isDarkMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}

// ============================================================
// TASK PAGE
// ============================================================

class TodoPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const TodoPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<TodoPage> createState() => _TodoPageState();
}

// ============================================================
// TASK PAGE STATE
// ============================================================

class _TodoPageState extends State<TodoPage> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController taskController =
      TextEditingController();

  final TextEditingController searchController =
      TextEditingController();

  // ==========================================================
  // DATA
  // ==========================================================

  final List<String> tasks = [];

  final List<bool> completed = [];

  final List<String> priorities = [];

  bool isLoading = true;

  String selectedFilter = 'All';

  String searchText = '';

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadTasks();

    searchController.addListener(() {
      setState(() {
        searchText =
            searchController.text.toLowerCase();
      });
    });
  }

  // ==========================================================
  // LOAD TASKS
  // ==========================================================

  Future<void> loadTasks() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedTasks =
        prefs.getStringList('tasks') ?? [];

    final savedCompleted =
        prefs.getStringList('completed') ?? [];

    final savedPriorities =
        prefs.getStringList('priorities') ?? [];

    if (!mounted) {
      return;
    }

    setState(() {
      tasks.clear();
      completed.clear();
      priorities.clear();

      tasks.addAll(savedTasks);

      for (final value in savedCompleted) {
        completed.add(value == 'true');
      }

      for (final value in savedPriorities) {
        priorities.add(value);
      }

      // Make sure completed list matches tasks list.
      while (completed.length < tasks.length) {
        completed.add(false);
      }

      while (completed.length > tasks.length) {
        completed.removeLast();
      }

      // Make sure priorities list matches tasks list.
      while (priorities.length < tasks.length) {
        priorities.add('Normal');
      }

      while (priorities.length > tasks.length) {
        priorities.removeLast();
      }

      isLoading = false;
    });
  }

  // ==========================================================
  // SAVE TASKS
  // ==========================================================

  Future<void> saveTasks() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      'tasks',
      tasks,
    );

    await prefs.setStringList(
      'completed',
      completed
          .map(
            (value) => value.toString(),
          )
          .toList(),
    );

    await prefs.setStringList(
      'priorities',
      priorities,
    );
  }

  // ==========================================================
  // ADD TASK
  // ==========================================================

  void addTask() {
    final task =
        taskController.text.trim();

    if (task.isEmpty) {
      return;
    }

    setState(() {
      tasks.add(task);
      completed.add(false);
      priorities.add('Normal');
    });

    taskController.clear();

    saveTasks();
  }

  // ==========================================================
  // COMPLETE / UNCOMPLETE TASK
  // ==========================================================

  void toggleTask(int index) {
    setState(() {
      completed[index] =
          !completed[index];
    });

    saveTasks();
  }

  // ==========================================================
  // DELETE TASK
  // ==========================================================

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      completed.removeAt(index);
      priorities.removeAt(index);
    });

    saveTasks();
  }

  // ==========================================================
  // EDIT TASK
  // ==========================================================

  void editTask(int index) {
    final TextEditingController
        editController =
        TextEditingController(
      text: tasks[index],
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Task',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: TextField(
            controller: editController,
            autofocus: true,

            decoration:
                const InputDecoration(
              hintText:
                  'Enter task name',

              border:
                  OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final newTask =
                    editController.text
                        .trim();

                if (newTask.isNotEmpty) {
                  setState(() {
                    tasks[index] =
                        newTask;
                  });

                  saveTasks();
                }

                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      editController.dispose();
    });
  }

  // ==========================================================
  // CHANGE PRIORITY
  // ==========================================================

  void changePriority(int index) {
    showModalBottomSheet(
      context: context,

      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Padding(
                padding:
                    EdgeInsets.all(20),

                child: Text(
                  'Select Priority',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.flag,
                ),

                title:
                    const Text('Low'),

                onTap: () {
                  setState(() {
                    priorities[index] =
                        'Low';
                  });

                  saveTasks();

                  Navigator.pop(
                    bottomSheetContext,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.flag,
                ),

                title:
                    const Text('Normal'),

                onTap: () {
                  setState(() {
                    priorities[index] =
                        'Normal';
                  });

                  saveTasks();

                  Navigator.pop(
                    bottomSheetContext,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.flag,
                ),

                title:
                    const Text('High'),

                onTap: () {
                  setState(() {
                    priorities[index] =
                        'High';
                  });

                  saveTasks();

                  Navigator.pop(
                    bottomSheetContext,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // CLEAR COMPLETED
  // ==========================================================

  void clearCompleted() {
    setState(() {
      for (
        int i = tasks.length - 1;
        i >= 0;
        i--
      ) {
        if (completed[i]) {
          tasks.removeAt(i);
          completed.removeAt(i);
          priorities.removeAt(i);
        }
      }
    });

    saveTasks();
  }

  // ==========================================================
  // REMAINING TASKS
  // ==========================================================

  int get remainingTasks {
    int count = 0;

    for (final value in completed) {
      if (!value) {
        count++;
      }
    }

    return count;
  }

  // ==========================================================
  // COMPLETED TASKS
  // ==========================================================

  int get completedTasks {
    int count = 0;

    for (final value in completed) {
      if (value) {
        count++;
      }
    }

    return count;
  }

  // ==========================================================
  // FILTER TASKS
  // ==========================================================

  List<int> get filteredIndexes {
    final List<int> indexes = [];

    for (
      int i = 0;
      i < tasks.length;
      i++
    ) {
      final bool matchesSearch =
          tasks[i]
              .toLowerCase()
              .contains(searchText);

      if (!matchesSearch) {
        continue;
      }

      if (selectedFilter == 'All') {
        indexes.add(i);
      }

      else if (
          selectedFilter == 'Active' &&
          !completed[i]) {
        indexes.add(i);
      }

      else if (
          selectedFilter == 'Completed' &&
          completed[i]) {
        indexes.add(i);
      }
    }

    return indexes;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    taskController.dispose();
    searchController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // LOADING
    // ========================================================

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    // ========================================================
    // MAIN SCREEN
    // ========================================================

    return Scaffold(
      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.indigo,
              size: 30,
            ),

            SizedBox(width: 10),

            Text(
              'My Tasks',

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip:
                'Change Theme',

            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),

            onPressed:
                widget.onThemeChanged,
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =================================================
              // SUBTITLE
              // =================================================

              Text(
                'Stay organized. Get things done.',

                style: TextStyle(
                  fontSize: 16,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // SEARCH
              // =================================================

              TextField(
                controller:
                    searchController,

                decoration:
                    InputDecoration(
                  hintText:
                      'Search tasks...',

                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                      searchText.isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(
                                Icons.clear,
                              ),

                              onPressed: () {
                                searchController
                                    .clear();
                              },
                            )
                          : null,

                  filled: true,

                  fillColor:
                      Theme.of(context)
                          .colorScheme
                          .surface,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(15),

                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // ADD TASK
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          taskController,

                      onSubmitted: (_) {
                        addTask();
                      },

                      decoration:
                          InputDecoration(
                        hintText:
                            'What needs to be done?',

                        prefixIcon:
                            const Icon(
                          Icons.edit_note,
                        ),

                        filled: true,

                        fillColor:
                            Theme.of(
                              context,
                            )
                                .colorScheme
                                .surface,

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),

                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  SizedBox(
                    height: 56,
                    width: 56,

                    child:
                        ElevatedButton(
                      onPressed:
                          addTask,

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.indigo,

                        foregroundColor:
                            Colors.white,

                        padding:
                            EdgeInsets.zero,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),

                      child:
                          const Icon(
                        Icons.add,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              // =================================================
              // STATISTICS
              // =================================================

              Row(
                children: [
                  Expanded(
                    child:
                        buildStatCard(
                      'Total',
                      tasks.length,
                      Icons.list_alt,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        buildStatCard(
                      'Active',
                      remainingTasks,
                      Icons.pending_actions,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        buildStatCard(
                      'Done',
                      completedTasks,
                      Icons.task_alt,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              // =================================================
              // FILTERS
              // =================================================

              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,

                child: Row(
                  children: [
                    buildFilterButton(
                      'All',
                    ),

                    buildFilterButton(
                      'Active',
                    ),

                    buildFilterButton(
                      'Completed',
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // TODAY HEADER
              // =================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    'TODAY',

                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  Text(
                    '$remainingTasks remaining',

                    style: TextStyle(
                      color:
                          Colors.grey.shade600,

                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // TASK LIST
              // =================================================

              if (filteredIndexes.isEmpty)
                SizedBox(
                  height: 300,
                  child:
                      buildEmptyState(),
                )
              else
                ListView.builder(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount:
                      filteredIndexes.length,

                  itemBuilder:
                      (context, position) {
                    final index =
                        filteredIndexes[
                            position];

                    return buildTaskCard(
                      index,
                    );
                  },
                ),

              // =================================================
              // CLEAR COMPLETED
              // =================================================

              if (completed.contains(true))
                Center(
                  child:
                      TextButton.icon(
                    onPressed:
                        clearCompleted,

                    icon: const Icon(
                      Icons
                          .cleaning_services,
                    ),

                    label: const Text(
                      'Clear Completed',
                    ),
                  ),
                ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STAT CARD
  // ==========================================================

  Widget buildStatCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,

        borderRadius:
            BorderRadius.circular(15),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.04,
            ),

            blurRadius: 8,

            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            '$value',

            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Text(
            title,

            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILTER BUTTON
  // ==========================================================

  Widget buildFilterButton(
    String filter,
  ) {
    final bool selected =
        selectedFilter == filter;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),

      child: ChoiceChip(
        label: Text(filter),

        selected: selected,

        onSelected: (_) {
          setState(() {
            selectedFilter =
                filter;
          });
        },
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget buildEmptyState() {
    String message =
        'No tasks yet.';

    String subtitle =
        'Add your first task above.';

    if (selectedFilter == 'Active') {
      message =
          'No active tasks.';

      subtitle =
          'You are all caught up!';
    }

    if (selectedFilter == 'Completed') {
      message =
          'No completed tasks.';

      subtitle =
          'Complete a task to see it here.';
    }

    if (searchText.isNotEmpty) {
      message =
          'No matching tasks.';

      subtitle =
          'Try another search.';
    }

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.task_alt,
            size: 70,
            color:
                Colors.grey.shade300,
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            message,

            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 20,

              fontWeight:
                  FontWeight.bold,

              color:
                  Colors.grey.shade500,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            subtitle,

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color:
                  Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TASK CARD
  // ==========================================================

  Widget buildTaskCard(
    int index,
  ) {
    final bool isCompleted =
        completed[index];

    final String priority =
        priorities[index];

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.05,
            ),

            blurRadius: 8,

            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 10,
          vertical: 5,
        ),

        // ====================================================
        // CHECKBOX
        // ====================================================

        leading: Checkbox(
          value: isCompleted,

          onChanged: (_) {
            toggleTask(index);
          },
        ),

        // ====================================================
        // TASK NAME
        // ====================================================

        title: Text(
          tasks[index],

          style: TextStyle(
            fontSize: 16,

            fontWeight:
                FontWeight.w500,

            decoration: isCompleted
                ? TextDecoration
                    .lineThrough
                : TextDecoration.none,

            color: isCompleted
                ? Colors.grey
                : null,
          ),
        ),

        // ====================================================
        // PRIORITY
        // ====================================================

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 6,
          ),

          child:
              GestureDetector(
            onTap: () {
              changePriority(
                index,
              );
            },

            child: Row(
              children: [
                Icon(
                  Icons.flag,

                  size: 15,

                  color:
                      getPriorityColor(
                    priority,
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  priority,

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight:
                        FontWeight.w500,

                    color:
                        getPriorityColor(
                      priority,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ====================================================
        // EDIT + DELETE
        // ====================================================

        trailing: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            IconButton(
              tooltip: 'Edit',

              icon:
                  const Icon(
                Icons
                    .edit_outlined,
              ),

              onPressed: () {
                editTask(index);
              },
            ),

            IconButton(
              tooltip: 'Delete',

              icon:
                  const Icon(
                Icons
                    .delete_outline,
              ),

              color:
                  Colors.red,

              onPressed: () {
                deleteTask(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PRIORITY COLOR
  // ==========================================================

  Color getPriorityColor(
    String priority,
  ) {
    if (priority == 'High') {
      return Colors.red;
    }

    if (priority == 'Low') {
      return Colors.green;
    }

    return Colors.orange;
  }
}