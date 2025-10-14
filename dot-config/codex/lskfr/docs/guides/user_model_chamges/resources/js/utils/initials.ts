/**
 * Generate initials from a name string.
 * Takes the first letter of each part of the name, with only first and last capitalized.
 * If name is a single word, returns the first letter capitalized.
<<<<<<< HEAD
 *
=======
 * 
>>>>>>> origin/develop
 * @param name The full name to generate initials from
 * @returns The generated initials
 */
export function getInitials(name: string): string {
  if (!name || typeof name !== 'string') {
    return '';
  }

  const parts = name.trim().split(/\s+/);
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // If only one part, return first letter capitalized
  if (parts.length === 1) {
    return parts[0].charAt(0).toUpperCase();
  }
<<<<<<< HEAD

  let initials = '';

  // Get first letter of each part
  parts.forEach((part, index) => {
    if (!part) return;

    const initial = part.charAt(0);

=======
  
  let initials = '';
  
  // Get first letter of each part
  parts.forEach((part, index) => {
    if (!part) return;
    
    const initial = part.charAt(0);
    
>>>>>>> origin/develop
    // Capitalize only first and last initials
    if (index === 0 || index === parts.length - 1) {
      initials += initial.toUpperCase();
    } else {
      initials += initial.toLowerCase();
    }
  });
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  return initials;
}
