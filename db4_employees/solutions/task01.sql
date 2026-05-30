WITH RECURSIVE subordinates AS (
    SELECT employeeid
    FROM employees
    WHERE employeeid = 1

    UNION ALL

    SELECT e.employeeid
    FROM employees e
    JOIN subordinates s ON e.managerid = s.employeeid
)
SELECT
    e.employeeid,
    e.name AS employeename,
    e.managerid,
    d.departmentname,
    r.rolename,
    (
        SELECT STRING_AGG(DISTINCT p.projectname, ', ' ORDER BY p.projectname)
        FROM projects p
        WHERE p.departmentid = e.departmentid
    ) AS projectnames,
    (
        SELECT STRING_AGG(t.taskname, ', ' ORDER BY t.taskname)
        FROM tasks t
        WHERE t.assignedto = e.employeeid
    ) AS tasknames
FROM subordinates s
JOIN employees e ON e.employeeid = s.employeeid
LEFT JOIN departments d ON d.departmentid = e.departmentid
LEFT JOIN roles r ON r.roleid = e.roleid
ORDER BY e.name;
