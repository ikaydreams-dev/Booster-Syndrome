import OpenAI from 'openai';

export class OpenAIService {
  private client: OpenAI;

  constructor(apiKey: string) {
    this.client = new OpenAI({ apiKey });
  }

  async generateCompletion(prompt: string, model: string = 'gpt-4'): Promise<string> {
    const completion = await this.client.chat.completions.create({
      model,
      messages: [{ role: 'user', content: prompt }],
    });

    return completion.choices[0]?.message?.content || '';
  }

  async generateEmbedding(text: string): Promise<number[]> {
    const response = await this.client.embeddings.create({
      model: 'text-embedding-ada-002',
      input: text,
    });

    return response.data[0].embedding;
  }

  async moderateContent(text: string): Promise<boolean> {
    const moderation = await this.client.moderations.create({
      input: text,
    });

    return moderation.results[0].flagged;
  }

  async generateImage(prompt: string, size: '256x256' | '512x512' | '1024x1024' = '1024x1024'): Promise<string> {
    const response = await this.client.images.generate({
      prompt,
      size,
      n: 1,
    });

    return response.data[0].url || '';
  }

  async transcribeAudio(audioFile: File): Promise<string> {
    const transcription = await this.client.audio.transcriptions.create({
      file: audioFile,
      model: 'whisper-1',
    });

    return transcription.text;
  }

  async chatWithHistory(messages: Array<{ role: string; content: string }>, model: string = 'gpt-4'): Promise<string> {
    const completion = await this.client.chat.completions.create({
      model,
      messages: messages as any,
    });

    return completion.choices[0]?.message?.content || '';
  }

  async streamCompletion(prompt: string, onChunk: (chunk: string) => void): Promise<void> {
    const stream = await this.client.chat.completions.create({
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }],
      stream: true,
    });

    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content || '';
      if (content) {
        onChunk(content);
      }
    }
  }
}
