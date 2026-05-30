WITH RECURSIVE descendant_tree AS (
    SELECT
        e.employeeid AS manager_id,
        e.employeeid AS subordinate_id
    FROM employees e

    UNION ALL

    SELECT
        dt.manager_id,
        e.employeeid
    FROM descendant_tree dt
    JOIN employees e ON e.managerid = dt.subordinate_id
    WHERE dt.manager_id <> e.employeeid
),
subordinate_counts AS (
    SELECT
        manager_id,
        COUNT(*) AS totalsubordinates
    FROM descendant_tree
    WHERE manager_id <> subordinate_id
    GROUP BY manager_id
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
    ) AS tasknames,
    sc.totalsubordinates
FROM employees e
JOIN roles r ON r.roleid = e.roleid
JOIN subordinate_counts sc ON sc.manager_id = e.employeeid
LEFT JOIN departments d ON d.departmentid = e.departmentid
WHERE r.rolename = 'Менеджер'
  AND sc.totalsubordinates > 0
ORDER BY e.name;
