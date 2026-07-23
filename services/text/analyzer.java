import java.util.*;
import java.util.regex.*;

public class TextAnalyzer {

    public static int countWords(String text) {
        if (text == null || text.trim().isEmpty()) {
            return 0;
        }
        return text.trim().split("\\s+").length;
    }

    public static int countSentences(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        Pattern pattern = Pattern.compile("[.!?]+");
        Matcher matcher = pattern.matcher(text);
        int count = 0;
        while (matcher.find()) {
            count++;
        }
        return count;
    }

    public static int countParagraphs(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        String[] paragraphs = text.split("\\n\\s*\\n");
        return paragraphs.length;
    }

    public static Map<String, Integer> wordFrequency(String text) {
        Map<String, Integer> frequency = new HashMap<>();

        if (text == null || text.isEmpty()) {
            return frequency;
        }

        String[] words = text.toLowerCase().split("\\W+");

        for (String word : words) {
            if (!word.isEmpty()) {
                frequency.put(word, frequency.getOrDefault(word, 0) + 1);
            }
        }

        return frequency;
    }

    public static List<Map.Entry<String, Integer>> topWords(String text, int n) {
        Map<String, Integer> frequency = wordFrequency(text);

        List<Map.Entry<String, Integer>> sorted = new ArrayList<>(frequency.entrySet());
        sorted.sort((a, b) -> b.getValue().compareTo(a.getValue()));

        return sorted.subList(0, Math.min(n, sorted.size()));
    }

    public static double averageWordLength(String text) {
        if (text == null || text.isEmpty()) {
            return 0.0;
        }

        String[] words = text.split("\\W+");
        int totalLength = 0;
        int count = 0;

        for (String word : words) {
            if (!word.isEmpty()) {
                totalLength += word.length();
                count++;
            }
        }

        return count == 0 ? 0.0 : (double) totalLength / count;
    }

    public static double averageSentenceLength(String text) {
        int words = countWords(text);
        int sentences = countSentences(text);
        return sentences == 0 ? 0.0 : (double) words / sentences;
    }

    public static List<String> extractEmails(String text) {
        List<String> emails = new ArrayList<>();
        Pattern pattern = Pattern.compile("\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b");
        Matcher matcher = pattern.matcher(text);

        while (matcher.find()) {
            emails.add(matcher.group());
        }

        return emails;
    }

    public static List<String> extractURLs(String text) {
        List<String> urls = new ArrayList<>();
        Pattern pattern = Pattern.compile("https?://[\\w.-]+(?:\\.[\\w.-]+)+[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=]*");
        Matcher matcher = pattern.matcher(text);

        while (matcher.find()) {
            urls.add(matcher.group());
        }

        return urls;
    }

    public static List<String> extractPhoneNumbers(String text) {
        List<String> phones = new ArrayList<>();
        Pattern pattern = Pattern.compile("\\+?\\d{1,3}?[-.\\s]?\\(?\\d{1,4}\\)?[-.\\s]?\\d{1,4}[-.\\s]?\\d{1,9}");
        Matcher matcher = pattern.matcher(text);

        while (matcher.find()) {
            phones.add(matcher.group());
        }

        return phones;
    }

    public static String removeHTMLTags(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        return text.replaceAll("<[^>]*>", "");
    }

    public static String removePunctuation(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        return text.replaceAll("\\p{Punct}", "");
    }

    public static String removeExtraWhitespace(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        return text.replaceAll("\\s+", " ").trim();
    }

    public static double readabilityScore(String text) {
        int words = countWords(text);
        int sentences = countSentences(text);

        if (words == 0 || sentences == 0) {
            return 0.0;
        }

        int syllables = 0;
        String[] wordArray = text.toLowerCase().split("\\W+");

        for (String word : wordArray) {
            if (!word.isEmpty()) {
                syllables += countSyllables(word);
            }
        }

        double avgWordsPerSentence = (double) words / sentences;
        double avgSyllablesPerWord = (double) syllables / words;

        return 206.835 - 1.015 * avgWordsPerSentence - 84.6 * avgSyllablesPerWord;
    }

    private static int countSyllables(String word) {
        word = word.toLowerCase();
        int count = 0;
        boolean previousWasVowel = false;

        for (int i = 0; i < word.length(); i++) {
            char c = word.charAt(i);
            boolean isVowel = "aeiouy".indexOf(c) != -1;

            if (isVowel && !previousWasVowel) {
                count++;
            }

            previousWasVowel = isVowel;
        }

        if (word.endsWith("e")) {
            count--;
        }

        return Math.max(1, count);
    }

    public static String longestWord(String text) {
        String[] words = text.split("\\W+");
        String longest = "";

        for (String word : words) {
            if (word.length() > longest.length()) {
                longest = word;
            }
        }

        return longest;
    }
}
