DECLARE @Categories table (Id int, ParentId int, Title varchar(25))

INSERT INTO @Categories VALUES 
(1,0,'Technologies'),
	(2,1,'Frontend'),
		(3,2,'Angular'),
			(4,3,'AngularJS'),
			(5,3,'Angular2'),
		(6,2,'ReactJS'),
	(7,1,'Backend'),
		(8,7,'C#'),
		(9,7,'Java'),
		(10,7,'Python');

WITH Tree AS(
SELECT *, Level = '/' + CAST(Parent.Id as nvarchar(max)) + '/', Breadcrumb = CAST(Parent.Title as nvarchar(max))
FROM @Categories as Parent
WHERE ParentId = 0
UNION ALL
SELECT Child.*, Level = Level + CAST(Child.Id as varchar) + '/', Breadcrumb = Breadcrumb + ' / ' + Child.Title
FROM Tree as Parent
JOIN @Categories as Child ON Child.ParentId = Parent.Id
)
SELECT Tree.Id,
Tree.ParentId,
Tree.Title,
Tree.Breadcrumb,
Tree.Level,
CAST(Level as hierarchyid) as HierarchyId 
FROM Tree
ORDER BY Level