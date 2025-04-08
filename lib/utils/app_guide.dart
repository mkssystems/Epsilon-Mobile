// lib/utils/app_guide.dart

const String gameMenuGuide = '''
Welcome to the Game Menu App!

This guide will help you quickly understand how to navigate and use the main features of the application:

### Your Client ID:
- Every user is assigned a unique **Client ID** upon first using the app. This ID helps identify you during gameplay.
- Your Client ID is displayed clearly at the top of the screen.

### Game Sessions:
- **Game Sessions** are instances of the game you can join to play with others.
- Each available session is listed on the main screen, labeled with a unique Session ID.

### Creating a Game Session:
- Tap on the **"Create"** button under **"Session Actions"** to start a new game session.
- Once created, this session will appear in the list for you and other players to join.

### Seed:
- The **Seed** is a unique number used to generate the game's labyrinth layout. Using the same seed number will always produce the same labyrinth.
- You can specify a custom Seed when creating a session if you wish to recreate or share specific labyrinth layouts with other players.
- If no Seed is specified, the game generates a random Seed for you.

### Labyrinth ID:
- Each labyrinth created is assigned a unique **Labyrinth ID**.
- The Labyrinth ID identifies a specific maze configuration and can help players communicate clearly about the layout or challenges within a particular game.
- You can see the Labyrinth ID displayed within each session's details.

### Refreshing Game Sessions:
- Tap **"Refresh"** under **"Session Actions"** to update and display the latest available game sessions.

### Joining a Game Session:
- Select any session from the list to view more details.
- Tap the **"Join"** button in the session details popup to connect to the selected session.
- Once joined, the session you are connected to will be highlighted in green.

### Leaving a Game Session:
- If you're currently in a session, you can leave by selecting the session from the list and tapping the **"Leave"** button.

### Entering the Game:
- After joining a session, an **"Enter Game"** button will be available (coming soon!). This button will allow you to enter and start playing the game.

Enjoy your gameplay experience!
''';
