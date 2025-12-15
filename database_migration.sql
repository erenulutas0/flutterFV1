-- Add difficulty column to sentences table
ALTER TABLE sentences ADD COLUMN difficulty VARCHAR(20) DEFAULT 'easy';

-- Update existing sentences to have easy difficulty (lowercase)
UPDATE sentences SET difficulty = 'easy' WHERE difficulty IS NULL;

-- Make difficulty column NOT NULL after setting default values
ALTER TABLE sentences ALTER COLUMN difficulty SET NOT NULL;

-- Update words table difficulty to lowercase for consistency
UPDATE words SET difficulty = LOWER(difficulty) WHERE difficulty IS NOT NULL;

-- Add index for better performance on difficulty queries
CREATE INDEX idx_sentences_difficulty ON sentences(difficulty);
CREATE INDEX idx_words_difficulty ON words(difficulty);
