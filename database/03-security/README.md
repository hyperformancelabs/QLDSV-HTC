# Security Scripts

This directory contains scripts to set up security principals (logins, users, roles) for the QLDSV-HTC database.

## SQL Server Login Management Best Practices

Based on SQL Server documentation and our experience, we've implemented a comprehensive approach to login management that addresses two main issues:

### 1. Password Policy DLL Error in Linux Containers

When running SQL Server in Docker containers (especially on Linux), you may encounter the following error during login creation:

```
Could not load the DLL (server internal), or one of the DLLs it references. Reason: 126(The specified module could not be found.). (17750)
```

**Root Cause:** SQL Server's password policy validation functionality requires Windows-specific DLLs that aren't available in Linux containers. This happens because the SQL Server engine attempts to validate passwords against Windows security policies.

**Solution:** We've implemented a multi-layered approach:

1. **In SQL Scripts:** Added `CHECK_POLICY = OFF` to all `CREATE LOGIN` statements, which tells SQL Server not to attempt password policy validation
2. **In Python Code:** Added specific error filtering to prevent unnecessary logging of these expected errors
3. **Error Handling:** Added proper T-SQL `TRY/CATCH` blocks to handle any errors during login processing

### 2. "Cannot drop login" Error During Database Reset

When resetting the database, you might see warnings like:

```
Cannot drop the login 'app_user', because it does not exist or you do not have permission. (15151)
```

**Root Cause:** This happens when the SQL script tries to drop a login that doesn't exist (common during first run or after container recreation).

**Solution:** We've implemented proper error handling:

1. **T-SQL TRY/CATCH Blocks:** Added proper exception handling in SQL scripts to catch and handle these errors gracefully
2. **Error Filtering:** Added specific filtering in Python code to avoid logging these expected errors
3. **Execution Strategy:** Improved the SQL execution strategy to try running the entire script first, then fall back to statement-by-statement execution if needed

## SQL Server Authentication Best Practices

Based on [Microsoft documentation](https://learn.microsoft.com/en-us/answers/questions/340305/security-related-login-password-change) and [AWS RDS guidelines](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/SQLServer.Concepts.General.PasswordPolicy.Using.html), we've implemented the following best practices:

### Password Settings

1. **CHECK_POLICY=OFF:** Disables Windows password policy validation - critical for cross-platform compatibility
2. **Using TRY/CATCH:** Properly handles login creation errors without stopping execution
3. **Proper Error Handling:** Filters out expected warnings from logs

### Security Principal Structure

| Login       | Purpose                            | Access Level |
|-------------|------------------------------------|--------------|
| app_user    | Application connection             | Server-wide  |
| pgv_user    | Phòng Giáo Vụ (PGV) role          | Full access  |
| khoa_user   | Khoa role                          | Limited      |
| sv_user     | Student (SV) role                  | Minimal      |

## References

1. [Microsoft Q&A: Security related Login password change](https://learn.microsoft.com/en-us/answers/questions/340305/security-related-login-password-change)
2. [AWS RDS: Using Password Policy for SQL Server logins](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/SQLServer.Concepts.General.PasswordPolicy.Using.html)
3. [SQL Server Password Policy Documentation](https://learn.microsoft.com/en-us/sql/relational-databases/policy-based-management/sql-server-login-password-expiration) 