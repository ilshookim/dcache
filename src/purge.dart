/// dfiles designed by ilshookim
/// MIT License
///
/// https://github.com/ilshookim/dfiles
///
import 'dart:async';
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dcli/src/functions/is.dart';
import 'package:stack_trace/stack_trace.dart';

import 'global.dart';

class Purge {
  int count = int.tryParse(Global.defaultCount)!;
  int days = int.tryParse(Global.defaultDays)!;
  int timer = int.tryParse(Global.defaultTimer)!;
  String monitor = absolute(Global.defaultMonitor);
  String monitorRecursive = Global.defaultRootRecursive;
  String printAll = Global.defaultPrintAll;

  Stopwatch _consume = Stopwatch();
  Timer? _timer;

  Purge({bool autostart = false}) {
    if (autostart) start();
  }

  bool get isActive => _timer != null && _timer!.isActive;
  bool get isRunning => _consume.isRunning;

  bool start() {
    final String function = Trace.current().frames[0].member!;
    bool succeed = false;
    try {
      if (isRunning) return succeed;
      final bool exists = Directory(monitor).existsSync();
      if (!exists) return succeed;
      if (!isActive) {
        final bool periodic = timer > 0;
        if (periodic) {
          final Duration seconds = Duration(seconds: timer);
          _timer = Timer.periodic(seconds, _purgeTimerPeriodic);
        } else {
          final Duration seconds = Duration(seconds: 1);
          _timer = Timer(seconds, _purgeTimer);
        }
        succeed = true;
      }
    } catch (exc) {
      print('$function: $exc');
    }
    return succeed;
  }

  bool stop() {
    final String function = Trace.current().frames[0].member!;
    bool succeed = false;
    try {
      if (isActive) {
        _timer!.cancel();
        succeed = true;
      }
    } catch (exc) {
      print('$function: $exc');
    }
    return succeed;
  }

  void _purgeTimerPeriodic(Timer timer) => _purgeTimer(once: false);
  void _purgeTimer({bool once = true}) {
    if (isRunning) return;
    final String function = Trace.current().frames[0].member!;
    int purged = 0;
    try {
      _consume.start();
      purged = purgeDirectory(monitor, monitorRecursive.parseBool(), once);
      _consume.stop();
    } catch (exc) {
      print('$function: $exc');
    } finally {
      final bool purgeInfo = purged > 0;
      if (purgeInfo) {
        final int consumed = _consume.elapsedMilliseconds;
        print(    'PURGED: count=$purged, consumed=$consumed <- monitor=$monitor, count=$count, days=$days, printAll=$printAll');
      }
    }
  }

  int purgeDirectory(String monitor,
      [bool monitorRecursive = true, bool once = true]) {
    final String function = Trace.current().frames[0].member!;
    int purged = 0;
    try {
      purged += purgeFiles(monitor, root: true);

      const String pattern = '*';
      const bool includeHidden = true;
      find(
        pattern,
        workingDirectory: monitor,
        recursive: monitorRecursive,
        includeHidden: includeHidden,
        types: [Find.directory],
        progress: Progress((String directory) {
          if (isActive || once) purged += purgeFiles(directory);
        }),
      );
    } catch (exc) {
      print('$function: $exc');
    }
    return purged;
  }

  int purgeFiles(String directory, {bool root = false}) {
    final String function = Trace.current().frames[0].member!;
    int purged = 0;
    try {
      final bool printAllFiles = printAll.parseBool();
      const bool recursive = false;
      const bool followLinks = false;
      final List<FileSystemEntity> files = Directory(directory).listSync(
        recursive: recursive,
        followLinks: followLinks,
      );

      if (!root && files.isEmpty) {
        try {
          print('>>> deleted: directory=$directory');
          deleteDir(directory);
          purged++;
        } catch (exc) {
          print('$function: $exc');
        }
        return purged;
      }

      int directories = 0;
      for (int i = 0; i < files.length; i++) {
        FileStat stat = files[i].statSync();
        final bool purge = basename(files[i].path) == Global.dsStoreFile;
        if (purge) {
          try {
            print(        '>>> deleted: file=${files[i].path}, type=${stat.type}, modified=${stat.modified}');
            delete(files[i].path);
            files.removeAt(i--);
            purged++;
          } catch (exc) {
            print('$function: $exc');
          }
        }
        if (printAllFiles && !purge)
          print(      'printAllFiles: file=${files[i].path}, type=${stat.type}, modified=${stat.modified}');
        if (stat.type == FileSystemEntityType.directory) {
          files.removeAt(i--);
          directories++;
        }
      }

      const bool purgeReally = true;
      final bool purgeDays = days > 0 ? true : false;
      final bool purgeCount = count > 0 ? files.length > count : false;
      final bool purgeHere = purgeDays || purgeCount;
      if (purgeHere) {
        files.sort((a, b) {
          final int l = (a as File).lastModifiedSync().millisecondsSinceEpoch;
          final int r = (b as File).lastModifiedSync().millisecondsSinceEpoch;
          return r.compareTo(l);
        });

        if (purgeDays) {
          final DateTime today = DateTime.now();
          for (int i = files.length - 1; i >= 0; i--) {
            final String file = files[i].path;
            final DateTime datetime = lastModified(file);
            final Duration difference = today.difference(datetime);
            final bool expired = difference.inDays >= days;
            if (expired) {
              try {
                print(            '>>> deleted: days=${difference.inDays}, file=$file, datetime=$datetime');
                if (purgeReally) delete(file);
                purged++;
              } catch (exc) {
                print('$function: $exc');
              }
            } else
              break;
          }
        }

        if (purgeCount) {
          final int length = files.length - purged;
          for (int i = count; i < length; i++) {
            try {
              final String file = files[i].path;
              final DateTime datetime = lastModified(file);
              print('>>> deleted: index=$i, file=$file, datetime=$datetime');
              if (purgeReally) delete(file);
              purged++;
            } catch (exc) {
              print('$function: $exc');
            }
          }
        }
      }

      final bool purgeInfo = purged == 0;
      if (purgeInfo)
        print(    '${Global.defaultApp}: directory=$directory, files=${files.length}, directories=$directories, count=$count, days=$days, printAll=$printAll');
    } catch (exc) {
      print('$function: $exc');
    }
    return purged;
  }
}
