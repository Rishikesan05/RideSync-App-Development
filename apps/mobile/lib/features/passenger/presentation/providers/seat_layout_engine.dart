class BusSeatBlueprint {
  final String seatNumber;
  final int row;
  final int column;
  final bool isAisle;
  final bool isSpacer;

  BusSeatBlueprint({
    required this.seatNumber,
    required this.row,
    required this.column,
    this.isAisle = false,
    this.isSpacer = false,
  });
}

class SeatLayoutEngine {
  static List<BusSeatBlueprint> generateLayout(String type) {
    if (type == '54') {
      return _generate54Layout();
    } else {
      return _generate35Layout();
    }
  }

  static List<BusSeatBlueprint> _generate54Layout() {
    final List<List<dynamic>> rows = [
      [1, 2, 'A', 3, 4, 5],
      [6, 7, 'A', 8, 9, 10],
      [11, 12, 'A', 13, 14, 15],
      [16, 17, 'A', 18, 19, 20],
      [21, 22, 'A', 23, 24, 25],
      [26, 27, 'A', 28, 29, 30],
      [31, 32, 'A', 33, 34, 35],
      [36, 37, 'A', 38, 39, 40],
      [41, 42, 'A', 43, 44, 45],
      [null, null, 'A', 46, 47, 48],
      [49, 50, 51, 52, 53, 54]
    ];
    return _mapRowsToBlueprint(rows);
  }

  static List<BusSeatBlueprint> _generate35Layout() {
    final List<List<dynamic>> rows = [
      [1, 2, 'A', 3, 4],
      [5, 6, 'A', 7, 8],
      [9, 10, 'A', 11, 12],
      [13, 14, 'A', 15, 16],
      [17, 18, 'A', 19, 20],
      [21, 22, 'A', 23, 24],
      [25, 26, 'A', 27, 28],
      [null, null, 'A', 29, 30],
      [31, 32, 33, 34, 35]
    ];
    return _mapRowsToBlueprint(rows);
  }

  static List<BusSeatBlueprint> _mapRowsToBlueprint(List<List<dynamic>> rows) {
    final List<BusSeatBlueprint> blueprints = [];
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final val = rows[r][c];
        if (val is int) {
          blueprints.add(BusSeatBlueprint(seatNumber: val.toString(), row: r, column: c));
        } else if (val == 'A') {
          blueprints.add(BusSeatBlueprint(seatNumber: 'aisle_$r', row: r, column: c, isAisle: true));
        } else {
          blueprints.add(BusSeatBlueprint(seatNumber: 'spacer_$r', row: r, column: c, isSpacer: true));
        }
      }
    }
    return blueprints;
  }
}
