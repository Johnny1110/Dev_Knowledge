# MySQL query optimization


---

<br>

Here's several ways to improve MySQL query efficiency

<br>

### 1. Do not using `select *`

<br>

there are negative effects of using SELECT *:

<br>

* Increased Query Analyzer Load:

    When executing a query like `SELECT * FROM` student, the analyzer will parse this script and inspect the student table, querying its metadata for columns. It will retrieve all column names.

    However, if you execute a query like `SELECT id, name, gender FROM student`, only three columns need parsing by the analyzer.

<br>

* Increased Unnecessary Network Payload and I/O Load:

    If there are large data types such as text or JSON stored in columns, using * to select all columns, when in reality you don't need them, results in unnecessary network, RAM, and I/O usage.

<br>

* Inability to Use Covering Indexes: (索引覆蓋)

    For instance, if there is an index on the student table, like name, executing   `SELECT name FROM student WHERE id = 1` queries the index table directly, without involve additional columns that need querying the main table again. This is known as a covering index.

    However, when executing `SELECT *`, all columns are queried, including those not indexed. This prevents the use of a covering index and requires querying all columns from the main table again, resulting in slower performance.


<br>
<br>
<br>
<br>

### 2. Joining a Small Table with a Big Table

<br>

If you intend to use join queries, it's advisable to join a small tabler with a big one.

A small table contains relatively few records and is appropriately indexed, allowing its index to efficently filter the large table. This approach decreases query load and increases effciency.

For example, consider two tables: "student" and "scores". The "student" table contaions 30 records. while "scores" holds 1 million. The "scores" table includes a foreign key, "student_id", referencing the "student" table with id.

The correct way to query "student" with "scores" is demonstrated below. 

```sql
SELECT * FROM student AS stu LEFT JOIN scores AS sco ON stu.id = sco.student_id;
```

<br>

In  this query, "student" is the primary table, and "scores" is the secondary one. With only 30 records, the primary table filters a small daaset. Subsequently, the query retrieves corresponding data from the secondary table. It's essential that "student_id" be indexed in the "scores" table.

Conversely, querying in the opposite manner, as shown below, is less efficient:

```sql
SELECT * FROM scores AS sco LEFT JOIN student AS stu ON stu.id = sco.student_id;
```

<br>

In this scenario, filtering 1 million records from the "scores" table before querying the "student" table is a bad idea.

<br>
<br>
<br>
<br>

### 3. Using Join Queries Instead of Subqueries

<br>

Sometimes, you can enhance query performance by using join queries instead of subqueries.

Consider the scenario of two tables, "student" and "scores", when we need to retrieve data from both table: including `scores.course_name`, `scores.score` and student table's data `student.name`.

and there's a sql query below:

```sql
select 
    (select student.name 
    from student 
    where student.id = scores.student_id),
    scores.course_name,
    scores.score 
from scores;
```

<br>

Instead of using subqueries, try join query like below:

```sql
select student.name
    scores.course_name,
    scores.score
from student as stu inner join scores as sco on stu.id = sco.student_id;
```

<br>

Join queries offer several advantages over subqueries:

* __Reduced Query Execution:__ Subqueries require executing two separate database queries—one for the outer query and another for each subquery. In contrast, join queries combine data retrieval into a single query, reducing overall query execution time.

* __Utilization of Indexes:__ Join queries can take advantage of indexes, leading to improved query efficiency. Subqueries may not utilize indexes efficiently, potentially impacting performance.

<br>
<br>
<br>
<br>

### 4. Improve Group By

<br>

If you're using `group by` in a sql query, it's advisable to create index for the cloumn that you're grouping by. if not, that may have a negitive impact on sql query.

For example:

```sql
select remarks from scores group by remarks; 
```

In this query, grouping is performed based on the "remarks" column. Creating an index for this column can significantly improve the performance of the query, especially when dealing with large datasets.

<br>
<br>
<br>
<br>

### 5. Using btach insert/update

<br>

whever 

