-- ============================================================================
-- Database Initialization Script
-- Creates quotes table and populates with famous quotes
-- ============================================================================

-- Create quotes table
CREATE TABLE quotes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    quote_text NVARCHAR(500) NOT NULL,
    author NVARCHAR(100) NOT NULL,
    category NVARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE()
);
GO

-- Create indexes for better performance
CREATE INDEX idx_author ON quotes(author);
CREATE INDEX idx_category ON quotes(category);
GO

-- Insert famous quotes
INSERT INTO quotes (quote_text, author, category) VALUES
('The only way to do great work is to love what you do.', 'Steve Jobs', 'Motivation'),
('Innovation distinguishes between a leader and a follower.', 'Steve Jobs', 'Innovation'),
('Life is what happens when you''re busy making other plans.', 'John Lennon', 'Life'),
('The future belongs to those who believe in the beauty of their dreams.', 'Eleanor Roosevelt', 'Dreams'),
('It is during our darkest moments that we must focus to see the light.', 'Aristotle', 'Inspiration'),
('The only impossible journey is the one you never begin.', 'Tony Robbins', 'Motivation'),
('Success is not final, failure is not fatal: it is the courage to continue that counts.', 'Winston Churchill', 'Success'),
('The way to get started is to quit talking and begin doing.', 'Walt Disney', 'Action'),
('Don''t let yesterday take up too much of today.', 'Will Rogers', 'Wisdom'),
('You learn more from failure than from success.', 'Unknown', 'Failure'),
('It''s not whether you get knocked down, it''s whether you get up.', 'Vince Lombardi', 'Resilience'),
('Whether you think you can or you think you can''t, you''re right.', 'Henry Ford', 'Mindset'),
('The only limit to our realization of tomorrow will be our doubts of today.', 'Franklin D. Roosevelt', 'Doubt'),
('Creativity is intelligence having fun.', 'Albert Einstein', 'Creativity'),
('Believe you can and you''re halfway there.', 'Theodore Roosevelt', 'Belief'),
('The best time to plant a tree was 20 years ago. The second best time is now.', 'Chinese Proverb', 'Wisdom'),
('Your time is limited, don''t waste it living someone else''s life.', 'Steve Jobs', 'Life'),
('The greatest glory in living lies not in never falling, but in rising every time we fall.', 'Nelson Mandela', 'Resilience'),
('The journey of a thousand miles begins with one step.', 'Lao Tzu', 'Journey'),
('Life is 10% what happens to me and 90% of how I react to it.', 'Charles Swindoll', 'Life'),
('Change your thoughts and you change your world.', 'Norman Vincent Peale', 'Mindset'),
('The mind is everything. What you think you become.', 'Buddha', 'Mind'),
('The best revenge is massive success.', 'Frank Sinatra', 'Success'),
('Do what you can, with what you have, where you are.', 'Theodore Roosevelt', 'Action'),
('Everything you''ve ever wanted is on the other side of fear.', 'George Addair', 'Fear'),
('Dream big and dare to fail.', 'Norman Vaughan', 'Dreams'),
('Act as if what you do makes a difference. It does.', 'William James', 'Impact'),
('Success usually comes to those who are too busy to be looking for it.', 'Henry David Thoreau', 'Success'),
('The secret of getting ahead is getting started.', 'Mark Twain', 'Action'),
('All our dreams can come true if we have the courage to pursue them.', 'Walt Disney', 'Dreams'),
('Don''t watch the clock; do what it does. Keep going.', 'Sam Levenson', 'Persistence'),
('A year from now you may wish you had started today.', 'Karen Lamb', 'Action'),
('Opportunities don''t happen. You create them.', 'Chris Grosser', 'Opportunity'),
('Try not to become a man of success. Rather become a man of value.', 'Albert Einstein', 'Value'),
('The only person you are destined to become is the person you decide to be.', 'Ralph Waldo Emerson', 'Destiny'),
('Go confidently in the direction of your dreams.', 'Henry David Thoreau', 'Dreams'),
('Everything has beauty, but not everyone can see.', 'Confucius', 'Beauty'),
('When I let go of what I am, I become what I might be.', 'Lao Tzu', 'Growth'),
('Happiness is not something ready made. It comes from your own actions.', 'Dalai Lama', 'Happiness'),
('In three words I can sum up everything I''ve learned about life: it goes on.', 'Robert Frost', 'Life'),
('The purpose of our lives is to be happy.', 'Dalai Lama', 'Purpose'),
('Life is really simple, but we insist on making it complicated.', 'Confucius', 'Simplicity'),
('May you live every day of your life.', 'Jonathan Swift', 'Life'),
('Life itself is the most wonderful fairy tale.', 'Hans Christian Andersen', 'Life'),
('Do not let making a living prevent you from making a life.', 'John Wooden', 'Balance'),
('Life is ours to be spent, not to be saved.', 'D. H. Lawrence', 'Life'),
('Keep smiling, because life is a beautiful thing.', 'Marilyn Monroe', 'Positivity'),
('Life is a long lesson in humility.', 'James M. Barrie', 'Humility'),
('The whole secret of a successful life is to find out what it is one''s destiny to do.', 'Henry Ford', 'Purpose'),
('Good friends, good books, and a sleepy conscience: this is the ideal life.', 'Mark Twain', 'Life');
GO

-- Create stored procedure for random quote selection
CREATE PROCEDURE GetRandomQuote
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        id,
        quote_text,
        author,
        category,
        created_at
    FROM quotes
    ORDER BY NEWID();
END;
GO

-- Create view for statistics
CREATE VIEW vw_QuoteStatistics AS
SELECT
    COUNT(*) AS total_quotes,
    COUNT(DISTINCT author) AS total_authors,
    COUNT(DISTINCT category) AS total_categories
FROM quotes;
GO

-- Display success message
DECLARE @QuoteCount INT;
SELECT @QuoteCount = COUNT(*) FROM quotes;

PRINT '✅ Database initialized successfully!';
PRINT 'Total quotes inserted: ' + CAST(@QuoteCount AS VARCHAR(10));
PRINT '';
PRINT 'Test with: SELECT * FROM quotes;';
PRINT 'Random quote: EXEC GetRandomQuote;';
GO
