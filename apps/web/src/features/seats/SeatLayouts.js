/**
 * Dynamic Seat Layout Generator for RideSync
 * Supports Sri Lankan Private Bus Layouts (2-2 and 2-3 configurations)
 */

export const BUS_LAYOUTS = {
  L35: '35',
  L54: '54'
};

/**
 * Generates a seat grid based on bus capacity
 * @param {string} type - '35' or '54'
 * @returns {Array} List of seat objects with row/col/number
 */
export const generateBusLayout = (type) => {
  const seats = [];
  
  if (type === BUS_LAYOUTS.L54) {
    const layout = [
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

    layout.forEach((row, rIndex) => {
      row.forEach((seatNum, cIndex) => {
        if (typeof seatNum === 'number') {
          seats.push({
            seatNumber: seatNum,
            row: rIndex,
            column: cIndex,
            status: 'available',
            type: 'standard'
          });
        } else if (seatNum === 'A') {
          seats.push({
            seatNumber: `aisle_${rIndex}_${cIndex}`,
            row: rIndex,
            column: cIndex,
            isAisle: true
          });
        } else {
          seats.push({
            seatNumber: `spacer_${rIndex}_${cIndex}`,
            row: rIndex,
            column: cIndex,
            isSpacer: true
          });
        }
      });
    });
  } else {
    const layout = [
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

    layout.forEach((row, rIndex) => {
      row.forEach((seatNum, cIndex) => {
        if (typeof seatNum === 'number') {
          seats.push({
            seatNumber: seatNum,
            row: rIndex,
            column: cIndex,
            status: 'available',
            type: 'standard'
          });
        } else if (seatNum === 'A') {
          seats.push({
            seatNumber: `aisle_${rIndex}_${cIndex}`,
            row: rIndex,
            column: cIndex,
            isAisle: true
          });
        } else {
          seats.push({
            seatNumber: `spacer_${rIndex}_${cIndex}`,
            row: rIndex,
            column: cIndex,
            isSpacer: true
          });
        }
      });
    });
  }

  return seats;
};

/**
 * Returns CSS grid configuration for the bus type
 */
export const getBusGridTemplate = (type) => {
  if (type === BUS_LAYOUTS.L54) {
    return "repeat(6, 1fr)";
  }
  return "repeat(5, 1fr)";
};
