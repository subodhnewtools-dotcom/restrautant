import 'package:drift/drift.dart';
import '../app_database.dart';

part 'printer_config_dao.g.dart';

@DriftAccessor(tables: [PrinterConfig])
class PrinterConfigDao extends DatabaseAccessor<AppDatabase> with _$PrinterConfigDaoMixin {
  Future<PrinterConfigItem?> getDefaultPrinter() async {
    final printers = await (select(printerConfig)..where((t) => t.isDefault.equals(true))).get();
    return printers.isNotEmpty ? printers.first : null;
  }

  Future<int> savePrinter(PrinterConfigCompanion printer) async {
    // First, unset all defaults
    await (update(printerConfig)).write(PrinterConfigCompanion(isDefault: Value(false)));
    
    // Then insert/update the new default
    return into(printerConfig).insert(printer, mode: InsertMode.insertOrReplace);
  }

  Future<bool> deletePrinter(int id) async {
    return (delete(printerConfig)..where((t) => t.id.equals(id))).go();
  }

  Future<List<PrinterConfigItem>> getAllPrinters() async {
    return (select(printerConfig)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]).get());
  }

  Stream<PrinterConfigItem?> watchDefaultPrinter() {
    return (select(printerConfig)..where((t) => t.isDefault.equals(true))).watchSingleOrNull();
  }
}
