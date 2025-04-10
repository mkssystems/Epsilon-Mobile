# labyrinth_manager.py

from models.labyrinth import Labyrinth
from models.tile import Tile
from models.entity_position import EntityPosition
from db.session import get_session
from utils.corrected_labyrinth_backend_seed_fixed import generate_labyrinth

class LabyrinthManager:
    """
    Manages labyrinth creation, dynamic changes, and retrieval of labyrinth state.
    """

    def __init__(self, session_id: str, labyrinth_id: str):
        self.session_id = session_id
        self.labyrinth_id = labyrinth_id

    def create_labyrinth(self, seed: str, size: tuple):
        """
        Generates a labyrinth based on provided seed and size.
        Stores the generated labyrinth in the database.
        """
        labyrinth_structure = generate_labyrinth(seed, size)
        
        with get_session() as db:
            labyrinth = Labyrinth(
                labyrinth_id=self.labyrinth_id,
                session_id=self.session_id,
                seed=seed,
                size=size,
                generated_tiles=labyrinth_structure
            )
            db.add(labyrinth)
            db.commit()

        return labyrinth_structure

    def get_labyrinth_structure(self):
        """
        Retrieves the current labyrinth structure from the database.
        """
        with get_session() as db:
            labyrinth = db.query(Labyrinth).filter_by(
                labyrinth_id=self.labyrinth_id,
                session_id=self.session_id
            ).first()

            return labyrinth.generated_tiles if labyrinth else None

    def update_connections(self, tile_a_id: str, tile_b_id: str, action: str):
        """
        Updates connections between two tiles explicitly.
        
        Parameters:
        - tile_a_id: ID of the first tile.
        - tile_b_id: ID of the second tile.
        - action: Type of action (e.g., 'connect', 'disconnect').
        """
        with get_session() as db:
            labyrinth = db.query(Labyrinth).filter_by(
                labyrinth_id=self.labyrinth_id,
                session_id=self.session_id
            ).first()

            if not labyrinth:
                raise ValueError("Labyrinth not found.")

            # Assuming labyrinth.generated_tiles is a dict structure
            if action == 'connect':
                labyrinth.generated_tiles['connections'].append([tile_a_id, tile_b_id])
            elif action == 'disconnect':
                labyrinth.generated_tiles['connections'].remove([tile_a_id, tile_b_id])

            db.commit()

    def track_entity_position(self, turn_number: int, entity_id: str, entity_type: str, tile_id: str):
        """
        Explicitly records entity position within the labyrinth for a given turn.
        
        Parameters:
        - turn_number: Current turn number.
        - entity_id: Identifier for the entity.
        - entity_type: Type of the entity (player, enemy, npc, etc.).
        - tile_id: Identifier for the tile position.
        """
        with get_session() as db:
            position = EntityPosition(
                session_id=self.session_id,
                labyrinth_id=self.labyrinth_id,
                turn_number=turn_number,
                entity_type=entity_type,
                entity_id=entity_id,
                tile_id=tile_id
            )
            db.add(position)
            db.commit()

    def get_entity_positions(self, turn_number: int):
        """
        Retrieves all entity positions explicitly for a given turn number.
        """
        with get_session() as db:
            positions = db.query(EntityPosition).filter_by(
                session_id=self.session_id,
                labyrinth_id=self.labyrinth_id,
                turn_number=turn_number
            ).all()

            return positions
