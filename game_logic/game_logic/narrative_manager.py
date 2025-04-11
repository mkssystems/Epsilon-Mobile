# narrative_manager.py

import random
from db.session import get_session
from models.game_entities import GameEntity
from models.labyrinth import Labyrinth

class NarrativeManager:
    """
    Explicitly generates dynamic, procedural-randomized narrative descriptions for game tiles.
    """

    def __init__(self, session_id: str, labyrinth_id: str):
        self.session_id = session_id
        self.labyrinth_id = labyrinth_id

    def get_random_tile_description(self, tile_id: str) -> str:
        """
        Retrieves random base description variant explicitly for a tile.
        """
        descriptions = self.get_tile_variants(tile_id)
        return random.choice(descriptions) if descriptions else "You see nothing remarkable."

    def get_tile_variants(self, tile_id: str) -> list:
        """
        Fetches explicitly predefined narrative variants for the tile from structured data.
        (For now, mock this method explicitly; later replace with real data fetch.)
        """
        # Placeholder implementation explicitly for future replacement with real data
        return [
            "The corridor is dimly lit, shadows dancing on the walls.",
            "You find yourself in a narrow passageway, quiet and still.",
            "A cold, metallic scent fills the air, hinting at recent events."
        ]

    def get_entities_description(self, tile_id: str, exclude_entity_id: str = None) -> str:
        """
        Explicitly generates descriptions of entities present on the tile, excluding the requesting entity.
        """
        with get_session() as db:
            entities = db.query(GameEntity).filter_by(
                labyrinth_id=self.labyrinth_id,
                current_tile_id=tile_id
            ).all()

            descriptions = []
            for entity in entities:
                if entity.entity_id != exclude_entity_id:
                    descriptions.append(f"{entity.name} is here.")

            return " ".join(descriptions)

    def generate_full_description(self, player_id: str, tile_id: str) -> str:
        """
        Generates full narrative explicitly combining tile description and entities present.
        """
        base_description = self.get_random_tile_description(tile_id)
        entities_description = self.get_entities_description(tile_id, exclude_entity_id=player_id)

        full_description = base_description
        if entities_description:
            full_description += f" {entities_description}"

        return full_description
