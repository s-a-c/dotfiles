# Security Best Practices Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of security best practices in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Authentication Security

### Questions

1. **What is the recommended way to store passwords in a Laravel application?**
   - A) In plain text
   - B) Using MD5 hashing
   - C) Using bcrypt or Argon2 hashing
   - D) Using SHA-1 hashing

2. **Which of the following is NOT a recommended practice for secure authentication?**
   - A) Implementing multi-factor authentication
   - B) Using rate limiting for login attempts
   - C) Storing session IDs in local storage
   - D) Implementing secure password reset functionality

3. **What is the purpose of Laravel Sanctum?**
   - A) To provide OAuth2 authentication
   - B) To provide API token authentication and SPA authentication
   - C) To provide LDAP authentication
   - D) To provide social authentication

### Exercise

**Implement a secure login system with the following features:**

1. Password strength validation
2. Rate limiting for login attempts
3. Two-factor authentication
4. Secure session configuration
5. Secure password reset functionality

Provide code snippets for each feature and explain how they contribute to security.

## Set 2: Authorization Best Practices

### Questions

1. **Which Laravel feature is used to define authorization rules for models?**
   - A) Middleware
   - B) Policies
   - C) Guards
   - D) Providers

2. **What is the purpose of the `can` middleware in Laravel?**
   - A) To check if a user can perform an action on a resource
   - B) To validate request input
   - C) To authenticate users
   - D) To rate limit requests

3. **How does the Spatie Laravel Permission package handle team-based permissions?**
   - A) It doesn't support team-based permissions
   - B) By adding a team_id column to the roles and permissions tables
   - C) By creating separate roles and permissions tables for each team
   - D) By using a many-to-many relationship between teams and permissions

### Exercise

**Implement a team-based authorization system with the following features:**

1. Role-based access control
2. Team-scoped permissions
3. Policy-based authorization
4. Blade directive authorization
5. API authorization

Provide code snippets for each feature and explain how they contribute to security.

## Set 3: CSRF and XSS Protection

### Questions

1. **What is the purpose of CSRF protection?**
   - A) To prevent cross-site scripting attacks
   - B) To prevent cross-site request forgery attacks
   - C) To prevent SQL injection attacks
   - D) To prevent brute force attacks

2. **How does Laravel protect against XSS attacks by default?**
   - A) By using the `{{ }}` syntax to automatically escape output
   - B) By using the `{!! !!}` syntax to automatically escape output
   - C) By using the `@csrf` directive
   - D) By using the `@method` directive

3. **Which of the following is a recommended practice for preventing XSS attacks?**
   - A) Using `{!! !!}` for all user-generated content
   - B) Disabling Laravel's automatic escaping
   - C) Implementing a Content Security Policy
   - D) Allowing inline scripts from any source

### Exercise

**Implement CSRF and XSS protection for a form that allows users to submit comments with formatted text:**

1. CSRF protection for the form
2. Input validation for the comment text
3. Safe output of the comment text
4. Content Security Policy configuration
5. HTML sanitization for formatted text

Provide code snippets for each feature and explain how they contribute to security.

## Set 4: SQL Injection Prevention

### Questions

1. **Which of the following is the most secure way to perform a database query with user input?**
   - A) Using string concatenation to build the query
   - B) Using raw SQL queries with user input
   - C) Using Eloquent or the Query Builder with parameter binding
   - D) Using DB::select with string concatenation

2. **What is the purpose of parameter binding in database queries?**
   - A) To improve query performance
   - B) To make queries more readable
   - C) To prevent SQL injection attacks
   - D) To reduce database load

3. **How should you handle dynamic table or column names in database queries?**
   - A) Use string concatenation
   - B) Use parameter binding
   - C) Validate against a whitelist of allowed names
   - D) Escape the names using a custom function

### Exercise

**Implement secure database queries for a search feature that allows users to search for products by name, category, and price range:**

1. Secure query for searching by name
2. Secure query for filtering by category
3. Secure query for filtering by price range
4. Secure handling of sorting by different columns
5. Secure pagination of results

Provide code snippets for each feature and explain how they contribute to security.

## Set 5: API Security

### Questions

1. **Which of the following is NOT a recommended practice for API security?**
   - A) Using HTTPS for all API requests
   - B) Implementing rate limiting
   - C) Storing API tokens in cookies without the HttpOnly flag
   - D) Validating all API input

2. **What is the purpose of API rate limiting?**
   - A) To improve API performance
   - B) To prevent abuse and DoS attacks
   - C) To reduce server load
   - D) To track API usage

3. **How does Laravel Sanctum handle SPA authentication?**
   - A) By using JWT tokens
   - B) By using session cookies and CSRF protection
   - C) By using basic authentication
   - D) By using OAuth2

### Exercise

**Implement a secure API for a blog application with the following features:**

1. Token-based authentication
2. Rate limiting
3. Input validation
4. Proper error handling
5. Secure response formatting

Provide code snippets for each feature and explain how they contribute to security.

## Set 6: Secure File Uploads

### Questions

1. **Which of the following is NOT a recommended practice for secure file uploads?**
   - A) Validating file types
   - B) Storing files with their original names
   - C) Limiting file size
   - D) Scanning files for viruses

2. **Where should uploaded files be stored in a Laravel application?**
   - A) In the public directory
   - B) In the storage directory
   - C) In the database
   - D) In the resources directory

3. **How can you prevent users from uploading malicious PHP files?**
   - A) By checking the file extension
   - B) By checking the MIME type
   - C) By using a combination of extension checking, MIME type validation, and file content analysis
   - D) By renaming all files to .txt

### Exercise

**Implement a secure file upload system for a document sharing application with the following features:**

1. File type validation
2. File size limitation
3. Secure file storage
4. File name sanitization
5. Secure file access control

Provide code snippets for each feature and explain how they contribute to security.

## Set 7: Security Headers

### Questions

1. **Which security header helps prevent clickjacking attacks?**
   - A) Content-Security-Policy
   - B) X-Content-Type-Options
   - C) X-Frame-Options
   - D) Strict-Transport-Security

2. **What is the purpose of the Content-Security-Policy header?**
   - A) To prevent cross-site scripting attacks
   - B) To prevent cross-site request forgery attacks
   - C) To prevent clickjacking attacks
   - D) To enforce HTTPS

3. **Which of the following is a recommended value for the X-Content-Type-Options header?**
   - A) `none`
   - B) `nosniff`
   - C) `same-origin`
   - D) `strict`

### Exercise

**Implement security headers for a web application with the following features:**

1. Content Security Policy
2. X-Frame-Options
3. X-Content-Type-Options
4. Strict-Transport-Security
5. Referrer-Policy

Provide code snippets for each header and explain how they contribute to security.

## Set 8: Security Testing

### Questions

1. **Which of the following is NOT a type of security testing?**
   - A) Static Application Security Testing (SAST)
   - B) Dynamic Application Security Testing (DAST)
   - C) Penetration Testing
   - D) Functional Testing

2. **What is the purpose of dependency scanning?**
   - A) To identify vulnerabilities in your code
   - B) To identify vulnerabilities in your dependencies
   - C) To identify performance issues
   - D) To identify code quality issues

3. **Which command is used to check for vulnerabilities in Composer dependencies?**
   - A) `composer check`
   - B) `composer scan`
   - C) `composer audit`
   - D) `composer security`

### Exercise

**Implement a security testing strategy for a web application with the following components:**

1. Automated security tests
2. Static analysis
3. Dependency scanning
4. Security headers testing
5. Penetration testing plan

Provide code snippets or configuration examples for each component and explain how they contribute to security.
