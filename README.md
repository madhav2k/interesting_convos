# AI Chatbot with Conversation Suggestions

A versatile AI chatbot that combines natural conversation with intelligent suggestion generation. Built using Ollama and Python, this tool helps you have engaging conversations while providing contextual suggestions.

## Features

### Chatbot Capabilities
- Natural conversation with AI using various open-source models
- Context-aware responses based on conversation history
- Multiple personality types and conversation moods
- Gender-aware communication preferences

### Available AI Models
- Mistral 7B (default) - Fast and efficient
- Llama 2 7B - Meta's open source model
- Code Llama - Specialized for code
- Neural Chat - Optimized for conversations
- Starling LM - Balanced performance

### Conversation Settings
- **Moods**: casual, formal, funny, romantic, flirtatious, professional, empathetic, enthusiastic, serious, playful, confident
- **Personality Types**: extroverted, introverted, ambivert, analytical, creative, practical, emotional, reserved
- **Gender Preferences**: male, female, non-binary, any

### Key Features
- Real-time conversation with AI
- Conversation suggestion generation
- User feedback collection
- Conversation history tracking
- Multiple conversation management
- Model switching capability

## Prerequisites

- Python 3.12 or higher
- Ollama installed and running
- Rye for dependency management

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Run the setup script:
```bash
./setup.sh
```

3. Start the application:
```bash
./run.sh
```

## Usage

### Basic Commands
- `help`: Show available commands
- `model`: Change AI model
- `mood`: Change conversation mood
- `personality`: Change personality type
- `gender`: Change gender preference
- `suggestions`: Get conversation suggestions
- `history`: View conversation history
- `chat`: Start chatting with AI
- `quit`: End current conversation and start new one
- `exit`: Exit the program

### Starting a Conversation
1. Launch the application
2. Choose to start a new conversation or continue an existing one
3. Select your preferred model, mood, personality, and gender settings
4. Start chatting or get suggestions

### Chat Mode
- Type `chat` to enter chat mode
- Have natural conversations with the AI
- Type `back` to return to command mode
- Type `quit` to end current conversation
- Type `exit` to quit the program

### Getting Suggestions
- Use the `suggestions` command to get contextual conversation suggestions
- Provide feedback on suggestions to improve future recommendations
- View conversation history with the `history` command

## File Structure

- `conversations.json`: Stores conversation history
- `feedback.json`: Stores user feedback on suggestions
- `conversation_suggester.py`: Main application code
- `setup.sh`: Installation script
- `run.sh`: Application launcher
- `cleanup.sh`: Cleanup script for Ollama processes

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details. 