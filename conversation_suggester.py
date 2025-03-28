import json
from typing import List, Dict
import os
from rich.console import Console
from rich.prompt import Prompt, Confirm
from rich.panel import Panel
from rich.table import Table
from ollama import Client
import time

console = Console()

class ConversationSuggester:
    def __init__(self):
        self.conversations_file = "conversations.json"
        self.feedback_file = "feedback.json"
        self.conversations = self._load_conversations()
        self.feedback = self._load_feedback()
        self.ollama_client = Client()
        self.available_models = {
            "mistral": "Mistral 7B - Fast and efficient",
            "llama2": "Llama 2 7B - Meta's open source model",
            "codellama": "Code Llama - Specialized for code",
            "neural-chat": "Neural Chat - Optimized for conversations",
            "starling-lm": "Starling LM - Balanced performance"
        }
        self.model = "mistral"  # Default model
        self.moods = {
            "casual": "Keep the tone light and friendly, like chatting with a friend",
            "formal": "Maintain a professional and respectful tone",
            "funny": "Include humor and wit while keeping it appropriate",
            "romantic": "Be flirty and romantic while being tasteful",
            "flirtatious": "Be playfully suggestive and charming while maintaining boundaries",
            "professional": "Focus on business and work-related topics",
            "empathetic": "Show understanding and emotional support",
            "enthusiastic": "Be energetic and positive",
            "serious": "Maintain a serious and focused tone",
            "playful": "Be light-hearted and playful",
            "confident": "Be assertive and self-assured"
        }
        self.personality_types = {
            "extroverted": "Be outgoing, energetic, and engaging",
            "introverted": "Be more reserved, thoughtful, and give space for reflection",
            "ambivert": "Balance between being engaging and giving space",
            "analytical": "Focus on logical discussion and problem-solving",
            "creative": "Encourage imaginative and artistic expression",
            "practical": "Focus on real-world applications and concrete examples",
            "emotional": "Be sensitive to feelings and emotional responses",
            "reserved": "Be more formal and maintain professional boundaries"
        }
        self.gender_preferences = {
            "male": "Adjust tone and topics for male audience",
            "female": "Adjust tone and topics for female audience",
            "non-binary": "Use inclusive language and avoid gender assumptions",
            "any": "Use neutral, inclusive language"
        }

    def _load_conversations(self) -> Dict:
        """Load existing conversations from JSON file."""
        if os.path.exists(self.conversations_file):
            with open(self.conversations_file, 'r') as f:
                return json.load(f)
        return {}

    def _load_feedback(self) -> Dict:
        """Load user feedback from JSON file."""
        if os.path.exists(self.feedback_file):
            with open(self.feedback_file, 'r') as f:
                return json.load(f)
        return {}

    def _save_conversations(self):
        """Save conversations to JSON file."""
        with open(self.conversations_file, 'w') as f:
            json.dump(self.conversations, f, indent=4)

    def _save_feedback(self):
        """Save user feedback to JSON file."""
        with open(self.feedback_file, 'w') as f:
            json.dump(self.feedback, f, indent=4)

    def add_conversation(self, person: str, messages: List[str]):
        """Add a new conversation or update existing one."""
        if person not in self.conversations:
            self.conversations[person] = []
        self.conversations[person].extend(messages)
        self._save_conversations()

    def _generate_prompt(self, person: str, recent_messages: List[str], mood: str, personality: str, gender: str, feedback_context: str = "") -> str:
        """Generate a prompt for the LLM based on the conversation context, mood, personality, gender, and feedback."""
        base_prompt = f"""You are a helpful conversation assistant. Analyze the following conversation with {person} and provide 3-4 natural, contextual suggestions for continuing the conversation. Make the suggestions specific to the context and personality of the conversation.

Conversation mood: {mood}
Mood guidelines: {self.moods[mood]}

Personality type: {personality}
Personality guidelines: {self.personality_types[personality]}

Gender preference: {gender}
Gender guidelines: {self.gender_preferences[gender]}

Recent messages:
{chr(10).join(recent_messages)}"""

        if feedback_context:
            base_prompt += f"""

User feedback and preferences:
{feedback_context}

Please adjust your suggestions based on this feedback, maintain the specified mood, and consider the personality type and gender preferences."""

        return base_prompt

    def _get_feedback_context(self, person: str) -> str:
        """Get relevant feedback context for the current conversation."""
        if person in self.feedback:
            feedback_list = self.feedback[person]
            if feedback_list:
                context = "Based on previous feedback:\n"
                for entry in feedback_list[-3:]:  # Use last 3 feedback entries
                    context += f"- {entry['feedback']} (Mood: {entry['mood']}, Rating: {entry['rating']}/5)\n"
                return context
        return ""

    def add_feedback(self, person: str, suggestion: str, feedback: str, rating: int, mood: str, personality: str, gender: str):
        """Add user feedback for a suggestion."""
        if person not in self.feedback:
            self.feedback[person] = []
        self.feedback[person].append({
            "suggestion": suggestion,
            "feedback": feedback,
            "rating": rating,
            "mood": mood,
            "personality": personality,
            "gender": gender,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
        })
        self._save_feedback()

    def get_suggestions(self, person: str, mood: str, personality: str, gender: str, num_messages: int = 5) -> List[str]:
        """Generate conversation suggestions using Ollama."""
        if person not in self.conversations:
            return ["I don't have any previous conversations with this person to base suggestions on."]
        
        recent_messages = self.conversations[person][-num_messages:]
        feedback_context = self._get_feedback_context(person)
        
        try:
            # Generate prompt
            prompt = self._generate_prompt(person, recent_messages, mood, personality, gender, feedback_context)
            
            # Get response from Ollama
            response = self.ollama_client.generate(
                model=self.model,
                prompt=prompt,
                stream=False
            )
            
            # Parse the response into suggestions
            suggestions = [s.strip() for s in response['response'].split('\n') if s.strip()]
            
            # If we got no suggestions, provide some fallback options
            if not suggestions:
                suggestions = [
                    "Ask an open-ended question about their day",
                    "Share a relevant personal experience",
                    "Express interest in their opinions or perspective",
                    "Ask about their plans or goals"
                ]
            
            return suggestions
            
        except Exception as e:
            console.print(f"[red]Error generating suggestions: {str(e)}[/red]")
            return ["I encountered an error while generating suggestions. Please try again."]

    def _generate_chat_prompt(self, person: str, recent_messages: List[str], mood: str, personality: str, gender: str) -> str:
        """Generate a prompt for the LLM to act as a chatbot."""
        base_prompt = f"""You are a helpful AI chatbot having a conversation with {person}. Respond naturally and engagingly to the user's messages.

Conversation mood: {mood}
Mood guidelines: {self.moods[mood]}

Personality type: {personality}
Personality guidelines: {self.personality_types[personality]}

Gender preference: {gender}
Gender guidelines: {self.gender_preferences[gender]}

Recent messages:
{chr(10).join(recent_messages)}

Respond as a chatbot in a natural, conversational way. Keep your response concise and engaging."""

        return base_prompt

    def chat_with_ai(self, person: str, mood: str, personality: str, gender: str) -> str:
        """Generate a chatbot response using Ollama."""
        if person not in self.conversations:
            return "Hello! I'm happy to chat with you. How can I help you today?"
        
        recent_messages = self.conversations[person][-5:]  # Use last 5 messages for context
        
        try:
            # Generate prompt
            prompt = self._generate_chat_prompt(person, recent_messages, mood, personality, gender)
            
            # Get response from Ollama
            response = self.ollama_client.generate(
                model=self.model,
                prompt=prompt,
                stream=False
            )
            
            return response['response'].strip()
            
        except Exception as e:
            console.print(f"[red]Error generating response: {str(e)}[/red]")
            return "I encountered an error. Please try again."

    def change_model(self, model_name: str):
        """Change the current model."""
        if model_name in self.available_models:
            self.model = model_name
            return True
        return False

    def get_model_info(self) -> str:
        """Get information about the current model."""
        return f"{self.model} - {self.available_models[self.model]}"

def display_suggestions(suggestions: List[str], mood: str, personality: str, gender: str):
    """Display suggestions in a nice format."""
    table = Table(title=f"Conversation Suggestions (Mood: {mood}, Personality: {personality}, Gender: {gender})")
    table.add_column("Number", style="cyan")
    table.add_column("Suggestion", style="green")
    
    for i, suggestion in enumerate(suggestions, 1):
        table.add_row(str(i), suggestion)
    
    console.print(table)

def select_mood(suggester: ConversationSuggester) -> str:
    """Let user select a mood for the conversation."""
    console.print("\n[bold]Select the mood for your conversation:[/bold]")
    mood_choices = list(suggester.moods.keys())
    for i, mood in enumerate(mood_choices, 1):
        console.print(f"{i}. {mood}")
    while True:
        try:
            choice = int(Prompt.ask("\nChoose a mood (enter number)", default="1"))
            if 1 <= choice <= len(mood_choices):
                return mood_choices[choice - 1]
            console.print("[red]Invalid choice. Please try again.[/red]")
        except ValueError:
            console.print("[red]Please enter a number.[/red]")

def select_personality(suggester: ConversationSuggester) -> str:
    """Let user select a personality type for the conversation."""
    console.print("\n[bold]Select the personality type:[/bold]")
    personality_choices = list(suggester.personality_types.keys())
    for i, personality in enumerate(personality_choices, 1):
        console.print(f"{i}. {personality}")
    while True:
        try:
            choice = int(Prompt.ask("\nChoose a personality type (enter number)", default="1"))
            if 1 <= choice <= len(personality_choices):
                return personality_choices[choice - 1]
            console.print("[red]Invalid choice. Please try again.[/red]")
        except ValueError:
            console.print("[red]Please enter a number.[/red]")

def select_gender(suggester: ConversationSuggester) -> str:
    """Let user select gender preference for the conversation."""
    console.print("\n[bold]Select gender preference:[/bold]")
    gender_choices = list(suggester.gender_preferences.keys())
    for i, gender in enumerate(gender_choices, 1):
        console.print(f"{i}. {gender}")
    while True:
        try:
            choice = int(Prompt.ask("\nChoose gender preference (enter number)", default="1"))
            if 1 <= choice <= len(gender_choices):
                return gender_choices[choice - 1]
            console.print("[red]Invalid choice. Please try again.[/red]")
        except ValueError:
            console.print("[red]Please enter a number.[/red]")

def select_model(suggester: ConversationSuggester) -> str:
    """Let user select a model for the conversation."""
    console.print("\n[bold]Select the AI model:[/bold]")
    model_choices = list(suggester.available_models.keys())
    for i, model in enumerate(model_choices, 1):
        console.print(f"{i}. {model} - {suggester.available_models[model]}")
    while True:
        try:
            choice = int(Prompt.ask("\nChoose a model (enter number)", default="1"))
            if 1 <= choice <= len(model_choices):
                return model_choices[choice - 1]
            console.print("[red]Invalid choice. Please try again.[/red]")
        except ValueError:
            console.print("[red]Please enter a number.[/red]")

def get_user_feedback(suggester: ConversationSuggester, person: str, suggestion: str, mood: str, personality: str, gender: str) -> bool:
    """Get user feedback for a suggestion."""
    console.print("\n[bold]Would you like to provide feedback for this suggestion?[/bold]")
    if not Confirm.ask("Provide feedback?", default=False):
        return False
        
    rating = Prompt.ask("Rate this suggestion (1-5)", choices=["1", "2", "3", "4", "5"])
    feedback = Prompt.ask("What did you like or dislike about this suggestion?")
    suggester.add_feedback(person, suggestion, feedback, int(rating), mood, personality, gender)
    return True

def main():
    suggester = ConversationSuggester()
    
    console.print(Panel.fit(
        "[bold blue]Welcome to the AI Chatbot![/bold blue]\n"
        "I'll help you have engaging conversations. Type 'exit' to quit, 'help' for commands.",
        title="AI Chatbot",
        border_style="blue"
    ))
    
    # Show current model
    console.print(f"\n[bold]Current model:[/bold] {suggester.get_model_info()}")
    
    # Show existing conversations if any
    if suggester.conversations:
        console.print("\n[bold]Existing conversations:[/bold]")
        for i, person in enumerate(suggester.conversations.keys(), 1):
            console.print(f"{i}. {person}")
        
        console.print("\n[bold]Options:[/bold]")
        console.print("1. Select existing conversation")
        console.print("2. Start new conversation")
        console.print("3. Exit")
        
        choice = Prompt.ask("\nWhat would you like to do?", choices=["1", "2", "3"])
        
        if choice == "1":
            while True:
                try:
                    choice = int(Prompt.ask("\nSelect conversation (enter number)", default="1"))
                    if 1 <= choice <= len(suggester.conversations):
                        person = list(suggester.conversations.keys())[choice - 1]
                        break
                    console.print("[red]Invalid choice. Please try again.[/red]")
                except ValueError:
                    console.print("[red]Please enter a number.[/red]")
        elif choice == "2":
            person = Prompt.ask("\nWho are you having a conversation with?")
        else:
            console.print("[yellow]Goodbye![/yellow]")
            return
    else:
        person = Prompt.ask("\nWho are you having a conversation with?")

    # Set initial conversation parameters
    mood = "casual"
    personality = "ambivert"
    gender = "any"
    
    console.print("\n[bold]Available commands:[/bold]")
    console.print("- [cyan]help[/cyan]: Show available commands")
    console.print("- [cyan]model[/cyan]: Change AI model")
    console.print("- [cyan]mood[/cyan]: Change conversation mood")
    console.print("- [cyan]personality[/cyan]: Change personality type")
    console.print("- [cyan]gender[/cyan]: Change gender preference")
    console.print("- [cyan]suggestions[/cyan]: Get conversation suggestions")
    console.print("- [cyan]history[/cyan]: View conversation history")
    console.print("- [cyan]chat[/cyan]: Start chatting with AI")
    console.print("- [cyan]quit[/cyan]: End current conversation and start new one")
    console.print("- [cyan]exit[/cyan]: Exit the program")
    
    while True:
        user_input = Prompt.ask("\n[bold]You[/bold]")
        
        if user_input.lower() == 'exit':
            console.print("[yellow]Goodbye![/yellow]")
            break
        elif user_input.lower() == 'quit':
            console.print("[yellow]Ending current conversation...[/yellow]")
            person = Prompt.ask("\nWho would you like to chat with?")
            continue
        elif user_input.lower() == 'help':
            console.print("\n[bold]Available commands:[/bold]")
            console.print("- [cyan]help[/cyan]: Show available commands")
            console.print("- [cyan]model[/cyan]: Change AI model")
            console.print("- [cyan]mood[/cyan]: Change conversation mood")
            console.print("- [cyan]personality[/cyan]: Change personality type")
            console.print("- [cyan]gender[/cyan]: Change gender preference")
            console.print("- [cyan]suggestions[/cyan]: Get conversation suggestions")
            console.print("- [cyan]history[/cyan]: View conversation history")
            console.print("- [cyan]chat[/cyan]: Start chatting with AI")
            console.print("- [cyan]quit[/cyan]: End current conversation and start new one")
            console.print("- [cyan]exit[/cyan]: Exit the program")
            continue
        elif user_input.lower() == 'model':
            new_model = select_model(suggester)
            if suggester.change_model(new_model):
                console.print(f"[green]Model changed to: {suggester.get_model_info()}[/green]")
            else:
                console.print("[red]Failed to change model. Please try again.[/red]")
            continue
        elif user_input.lower() == 'mood':
            mood = select_mood(suggester)
            console.print(f"[green]Mood changed to: {mood}[/green]")
            continue
        elif user_input.lower() == 'personality':
            personality = select_personality(suggester)
            console.print(f"[green]Personality changed to: {personality}[/green]")
            continue
        elif user_input.lower() == 'gender':
            gender = select_gender(suggester)
            console.print(f"[green]Gender preference changed to: {gender}[/green]")
            continue
        elif user_input.lower() == 'suggestions':
            with console.status("[bold blue]Generating suggestions...[/bold blue]"):
                suggestions = suggester.get_suggestions(person, mood, personality, gender)
                time.sleep(1)
            display_suggestions(suggestions, mood, personality, gender)
            
            # Ask for feedback on each suggestion
            for suggestion in suggestions:
                if get_user_feedback(suggester, person, suggestion, mood, personality, gender):
                    console.print("[green]Feedback saved![/green]")
                else:
                    console.print("[yellow]Skipping feedback for this suggestion.[/yellow]")
            continue
        elif user_input.lower() == 'history':
            if person in suggester.conversations and suggester.conversations[person]:
                console.print("\n[bold]Conversation History:[/bold]")
                for i, message in enumerate(suggester.conversations[person], 1):
                    console.print(f"{i}. {message}")
            else:
                console.print("[yellow]No messages in this conversation yet.[/yellow]")
            continue
        elif user_input.lower() == 'chat':
            console.print("\n[bold]Starting chat mode. Type 'back' to return to command mode, 'quit' to end conversation, or 'exit' to quit program.[/bold]")
            while True:
                chat_input = Prompt.ask("\n[bold]You[/bold]")
                if chat_input.lower() == 'back':
                    break
                elif chat_input.lower() == 'quit':
                    console.print("[yellow]Ending current conversation...[/yellow]")
                    person = Prompt.ask("\nWho would you like to chat with?")
                    break
                elif chat_input.lower() == 'exit':
                    console.print("[yellow]Goodbye![/yellow]")
                    return
                
                # Add the user's message to the conversation
                suggester.add_conversation(person, [chat_input])
                
                # Generate and display AI response
                with console.status("[bold blue]Thinking...[/bold blue]"):
                    response = suggester.chat_with_ai(person, mood, personality, gender)
                    time.sleep(1)
                
                console.print(f"\n[bold blue]AI[/bold blue]: {response}")
                # Add the AI's response to the conversation
                suggester.add_conversation(person, [response])
            continue
        
        console.print("[yellow]Type 'help' to see available commands or 'chat' to start chatting with the AI.[/yellow]")

if __name__ == "__main__":
    main() 