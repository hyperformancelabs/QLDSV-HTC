/**
 * Utility functions for academic calendar related calculations
 */

/**
 * Returns the current academic semester (1, 2, or 3) based on the current month
 * - Semester 1: August-January (months 8-12, 1)
 * - Semester 2: February-May (months 2-5)
 * - Semester 3: June-July (months 6-7)
 */
export function getCurrentSemester(): number {
  const month = new Date().getMonth() + 1; // JavaScript months are 0-indexed
  
  if ((month >= 8 && month <= 12) || month === 1) {
    return 1; // Semester 1
  } else if (month >= 2 && month <= 5) {
    return 2; // Semester 2
  } else {
    return 3; // Semester 3 (months 6-7)
  }
}

/**
 * Returns the current academic year in the format "YYYY-YYYY"
 * - If current month >= 8 (August), academic year starts this calendar year
 * - Otherwise, academic year started previous calendar year
 */
export function getCurrentAcademicYear(): string {
  const currentDate = new Date();
  const currentMonth = currentDate.getMonth() + 1; // JavaScript months are 0-indexed
  const currentYear = currentDate.getFullYear();
  
  // Academic year always spans two calendar years (e.g., 2023-2024)
  // If we're in August or later, the academic year starts this calendar year
  // Otherwise, it started in the previous calendar year
  const startYear = currentMonth >= 8 ? currentYear : currentYear - 1;
  const endYear = startYear + 1;
  
  return `${startYear}-${endYear}`;
}

/**
 * Checks if a semester is in the past
 * @param academicYear - Academic year in format "YYYY-YYYY"
 * @param semester - Semester number (1, 2, or 3)
 */
export function isSemesterInPast(academicYear: string, semester: number): boolean {
  const startYear = parseInt(academicYear.split('-')[0], 10);
  const currentYear = new Date().getFullYear();
  const currentMonth = new Date().getMonth() + 1;
  const currentSemester = getCurrentSemester();
  const currentAcademicStartYear = currentMonth >= 8 ? currentYear : currentYear - 1;
  
  // If academic year is before current academic year
  if (startYear < currentAcademicStartYear) {
    return true;
  }
  
  // If same academic year but semester is before current semester
  if (startYear === currentAcademicStartYear && semester < currentSemester) {
    return true;
  }
  
  return false;
}

/**
 * Get an array of academic years for selection
 * Returns current academic year and 2 years before and after
 */
export function getAcademicYearOptions(): string[] {
  const currentYear = new Date().getFullYear();
  return Array.from({ length: 5 }, (_, i) => {
    const startYear = currentYear - 2 + i;
    return `${startYear}-${startYear + 1}`;
  });
} 