import 'package:flutter/material.dart';
import 'package:my_app/utils/mp_pose_class_custom.dart';
import 'package:provider/provider.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:my_app/screens/main.dart';
import 'package:my_app/services/provider_class.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/MP_pose_estimation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/data_csv_export.dart';
import 'package:my_app/utils/google_service_account.dart';

/// The class containing the TableView for the sample application.
class PoseDataTable extends StatefulWidget {
  final List<PoseEstimationData> poseData;

  const PoseDataTable({super.key, required this.poseData});

  @override
  State<PoseDataTable> createState() => _PoseDataTableState();
}

class _PoseDataTableState extends State<PoseDataTable> {
  PoseEstimationMediapipe poseEstimationMediapipe = PoseEstimationMediapipe();
  // controller for scrolling
  late final ScrollController _verticalController = ScrollController();

  String selectedBodypart = "ALL";

  final bodyparts = [
    "ALL",
    for (final type in PoseLandmarkType.values) type.toString().split('.')[1],
  ];
  // empty table for the final data
  List<Map<String, dynamic>> tableData = [];

  List<String> columnNames = [
    'id',
    'timestamp',
    'body_part',
    'x',
    'y',
    'z',
    'likelihood'
  ];

  @override
  void initState() {
    super.initState();
    tableData = convertPoseLandmarkData(widget.poseData);
    // Transform the data once in the init state
    transformData();
  }

  // A function that transforms the data for the table based on selection
  void transformData() {
    tableData.clear();
    if (selectedBodypart == "ALL") {
      tableData = convertPoseLandmarkData(widget.poseData);
      // Expand the pose data and map each row
    } else {
      setState(() {
        // If a specific body part is selected, filter the converted data
        tableData = tableData
            .where((row) => row["body_part"] == selectedBodypart)
            .toList();
      });
    }
  }

  // function to clear the data table completely
  void clearData() async {
    // Show confirmation dialog
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pose Data'),
        content: const Text(
            'Are you sure you want to clear all pose data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Clear Data', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldClear!) {
      // Clear pose data from the service globally and locally
      poseEstimationMediapipe.clearPoseData();
      widget.poseData.clear();
      tableData.clear();

      // Clear table data and update UI
      setState(() {
        tableData = [];
        _verticalController.jumpTo(0); // Scroll to top
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pose data cleared successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent)),
      child: Scaffold(
        //backgroundColor: thirdColor,
        appBar: AppBar(
          title: Text(
            'Pose Data',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, // Customize as needed
              fontSize: 29.0,
              color: Colors.white, // Optional color customization
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white), // Change color to blue
            onPressed: () => Navigator.of(context).pop(),
            iconSize: 30,
          ),
          backgroundColor: thirdColor,
          actions: [
            DropdownButton<String>(
              value: selectedBodypart,
              alignment: Alignment.centerRight,
              items: bodyparts
                  .map((bodypart) => DropdownMenuItem(
                      value: bodypart,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          bodypart,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )))
                  .toList(),
              onChanged: (newBodypart) {
                setState(() {
                  selectedBodypart = newBodypart!;
                  transformData();
                });
              },
              dropdownColor:
                  thirdColor, // Set the background color of the dropdown menu
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white, // Set the color of the arrow icon
                size: 28.0, // Increase the size of the arrow icon
              ),
              iconEnabledColor:
                  Colors.white, // Set the color of the enabled arrow icon
              underline: Container(), // Remove the underline
            ),
          ],
          titleSpacing: 15,
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _buildDataTable(context)),
        persistentFooterButtons: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(
              onPressed: () {
                _verticalController.jumpTo(0);
              },
              icon: const Icon(Icons.arrow_circle_up_sharp),
              color: Colors.white,
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                _verticalController
                    .jumpTo(_verticalController.position.maxScrollExtent);
              },
              icon: const Icon(Icons.arrow_circle_down_sharp),
              color: Colors.white,
              iconSize: 40,
            ),
            const SizedBox(width: 40),
            IconButton(
              onPressed: () {
                clearData();
              },
              icon: const Icon(Icons.delete_sweep_rounded),
              color: const Color.fromARGB(255, 196, 23, 10),
              iconSize: 42,
            ),
            IconButton(
              onPressed: context.watch<PoseEstimationProvider>().value
                  ? null
                  : () async {
                      uploadFiletoDrive(
                          poseDataToCSV(widget.poseData), context);
                    },
              icon: context.watch<PoseEstimationProvider>().value
                  ? const Icon(Icons.file_download_off,
                      color: Color.fromARGB(255, 31, 8, 160))
                  : const Icon(Icons.add_to_drive, color: primaryColor),
              iconSize: 39,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return TableView.builder(
      verticalDetails:
          ScrollableDetails.vertical(controller: _verticalController),
      cellBuilder: _buildCell,
      columnCount: columnNames.length,
      columnBuilder: _buildColumnSpan,
      rowCount: tableData.length + 1,
      rowBuilder: _buildRowSpan,
      pinnedRowCount: 1,
    );
  }

  TableViewCell _buildHeaderCell(String columnName) {
    return TableViewCell(
      child: Center(
        child: Text(
          columnName,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17.5,
              letterSpacing: 1.3 // Optionally style header text
              ),
        ),
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    if (vicinity.row == 0) {
      return _buildHeaderCell(columnNames
          .map((name) => name.toUpperCase())
          .toList()[vicinity.column]);
    } else {
      var poseDataRow = tableData[vicinity.row - 1];
      String columnName = columnNames[vicinity.column]; // Get column name
      dynamic value = poseDataRow[columnName]; // Access value using column name

      if (value is num && value is! int) {
        // Use NumberFormat for formatting numbers
        final formatter = NumberFormat.decimalPatternDigits(decimalDigits: 5);

        value = formatter.format(value);
      } else if (value is DateTime) {
        final dateTimeFormatter = DateFormat('yyyy-MM-dd hh:mm:ss.SSS');
        value = dateTimeFormatter.format(value); // Directly format the DateTime
      }

      // Display the value
      return TableViewCell(
        child: Center(
          child: Text(value.toString(),
              style:
                  const TextStyle(color: Color.fromARGB(221, 255, 255, 255))),
        ),
      );
    }
  }

  TableSpan _buildColumnSpan(int index) {
    const TableSpanDecoration decoration = TableSpanDecoration(
      border: TableSpanBorder(
        trailing: BorderSide(color: primaryColor, width: 1),
      ),
    );
    if (index == 1) {
      return const TableSpan(
          foregroundDecoration: decoration, extent: FixedTableSpanExtent(180));
    } else if (index == 2) {
      return const TableSpan(
          foregroundDecoration: decoration, extent: FixedTableSpanExtent(130));
    } else if (index == 6) {
      return const TableSpan(
          foregroundDecoration: decoration, extent: FixedTableSpanExtent(130));
    } else {
      return const TableSpan(
          foregroundDecoration: decoration, extent: FixedTableSpanExtent(100));
    }
  }

  TableSpan _buildRowSpan(int index) {
    const TableSpanDecoration decoration = TableSpanDecoration(
      color: thirdColor,
      border: TableSpanBorder(
        trailing: BorderSide(
          color: primaryColor,
          width: 1,
        ),
      ),
    );

    if (index == 0) {
      // Header row
      return const TableSpan(
          extent: FixedTableSpanExtent(45),
          backgroundDecoration: TableSpanDecoration(
              color: primaryColor,
              border: TableSpanBorder(
                  trailing: BorderSide(width: 1, color: primaryColor))));
    } else {
      return const TableSpan(
        backgroundDecoration: decoration,
        extent: FixedTableSpanExtent(50),
      );
    }
  }
}
