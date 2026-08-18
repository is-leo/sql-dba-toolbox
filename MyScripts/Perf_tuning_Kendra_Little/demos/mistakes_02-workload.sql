
EXEC dbo.GetTopQuestionsByTag 'mongodb'
EXEC dbo.GetTopQuestionsByTag 'javascript'

EXEC dbo.GetAnswersByQuestion 1
EXEC dbo.GetAnswersByQuestion 23930

EXEC dbo.GetQuestionsByUser 10
EXEC dbo.GetQuestionsByUser 147601

EXEC dbo.GetCommentsByUser 68183
EXEC dbo.GetCommentsByUser 100

EXEC dbo.GetTopUsersByReputation

EXEC dbo.GetQuestionsByTagAndUser 'xml', 147
EXEC dbo.GetQuestionsByTagAndUser 'javascript', 147601

EXEC dbo.GetCommentsByPost 1322
EXEC dbo.GetCommentsByPost 13

EXEC dbo.GetTopQuestionsByUser 1
EXEC dbo.GetTopQuestionsByUser 68183

EXEC dbo.GetAnswersByUser 68183
EXEC dbo.GetAnswersByUser 1

EXEC dbo.GetQuestionsByTag 'VB4'
EXEC dbo.GetQuestionsByTag 'javascript'

EXEC dbo.GetTopUsersByAnswerCount

EXEC dbo.GetQuestionsByTitle 'Visual Basic'
EXEC dbo.GetQuestionsByTitle 'js'

EXEC dbo.GetTopTagsByQuestionCount

EXEC dbo.GetTopUsersByQuestionCount

EXEC dbo.GetAnswersByTag 'fortran'
EXEC dbo.GetAnswersByTag 'c#'

EXEC dbo.GetTopTagsByCommentCount

EXEC dbo.GetTopUsersByCommentCount

EXEC dbo.GetQuestionsByTagAndTitle 'cobol', 'error'
EXEC dbo.GetQuestionsByTagAndTitle 'javascript', 'node.js'

EXEC dbo.GetAnswersByTagAndUser 'meta', 1

EXEC dbo.GetQuestionsByTagAndUserAndTitle 'javascript', 2138, 'node.js'
