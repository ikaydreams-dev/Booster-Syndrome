from abc import ABC, abstractmethod
from typing import Any, Dict, List
from dataclasses import dataclass
from datetime import datetime

@dataclass
class Command:
    """Base command class"""
    command_id: str
    timestamp: datetime
    user_id: str

@dataclass
class CreateUserCommand(Command):
    email: str
    password: str

@dataclass
class UpdateUserCommand(Command):
    user_id: int
    email: str = None
    password: str = None

@dataclass
class DeleteUserCommand(Command):
    user_id: int

class CommandHandler(ABC):
    """Base command handler"""
    
    @abstractmethod
    def handle(self, command: Command) -> Any:
        """Handle the command"""
        pass
    
    @abstractmethod
    def validate(self, command: Command) -> List[str]:
        """Validate the command, return list of errors"""
        pass

class CreateUserHandler(CommandHandler):
    """Handler for CreateUserCommand"""
    
    def __init__(self, user_repository, event_bus):
        self.user_repository = user_repository
        self.event_bus = event_bus
    
    def validate(self, command: CreateUserCommand) -> List[str]:
        errors = []
        
        if not command.email:
            errors.append("Email is required")
        
        if not command.password or len(command.password) < 8:
            errors.append("Password must be at least 8 characters")
        
        # Check if email already exists
        if self.user_repository.find_by_email(command.email):
            errors.append("Email already exists")
        
        return errors
    
    def handle(self, command: CreateUserCommand) -> Dict[str, Any]:
        errors = self.validate(command)
        if errors:
            return {'success': False, 'errors': errors}
        
        user = self.user_repository.create({
            'email': command.email,
            'password': command.password
        })
        
        # Publish event
        self.event_bus.publish('user.created', {
            'user_id': user.id,
            'email': user.email,
            'timestamp': datetime.now().isoformat()
        })
        
        return {'success': True, 'user': user}

class UpdateUserHandler(CommandHandler):
    """Handler for UpdateUserCommand"""
    
    def __init__(self, user_repository, event_bus):
        self.user_repository = user_repository
        self.event_bus = event_bus
    
    def validate(self, command: UpdateUserCommand) -> List[str]:
        errors = []
        
        user = self.user_repository.find(command.user_id)
        if not user:
            errors.append("User not found")
        
        return errors
    
    def handle(self, command: UpdateUserCommand) -> Dict[str, Any]:
        errors = self.validate(command)
        if errors:
            return {'success': False, 'errors': errors}
        
        update_data = {}
        if command.email:
            update_data['email'] = command.email
        if command.password:
            update_data['password'] = command.password
        
        user = self.user_repository.update(command.user_id, update_data)
        
        # Publish event
        self.event_bus.publish('user.updated', {
            'user_id': user.id,
            'changes': update_data,
            'timestamp': datetime.now().isoformat()
        })
        
        return {'success': True, 'user': user}

class CommandBus:
    """Command bus for routing commands to handlers"""
    
    def __init__(self):
        self.handlers: Dict[type, CommandHandler] = {}
    
    def register(self, command_type: type, handler: CommandHandler):
        """Register a handler for a command type"""
        self.handlers[command_type] = handler
    
    def dispatch(self, command: Command) -> Any:
        """Dispatch a command to its handler"""
        handler = self.handlers.get(type(command))
        
        if not handler:
            raise ValueError(f"No handler registered for {type(command).__name__}")
        
        return handler.handle(command)
