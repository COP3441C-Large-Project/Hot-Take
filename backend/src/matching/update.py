"""
Update user embedding based on new prompt.

Input (from Node.js via JSON):
  - userEmbedding: current user embedding (list of floats)
  - newPrompt: new prompt text (string)
  - lastUpdateTimestamp: last update timestamp in seconds (number)
  - lastEmbedding: previous topic embedding (list of floats)

Output (to Node.js as JSON):
  - updatedEmbedding: updated user embedding (list of floats)
  - skipped: boolean indicating if update was skipped due to high similarity
  - similarity: cosine similarity between last and new embedding
"""

import json
import sys
import time
from typing import Dict, List, Any
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity


# Load miniLM model
MODEL_NAME = "all-MiniLM-L6-v2"
model = SentenceTransformer(MODEL_NAME)

# Constants. These can be tuned based on experimentation and requirements.
# Similarity threshold above which we skip the update (0.8 means 80% similar)
#we might have to reduce this treshoold, at matching treshold a lot. Should experiment to
SIMILARITY_THRESHOLD = 0.8
THREE_MONTHS_SECONDS = 2 * 30 * 24 * 60 * 60  # Approximate 3 months in seconds
MAX_UPDATE_COEFFICIENT = 0.5


def calculate_update_coefficient(last_update_timestamp: float) -> float:
    """
    Calculate update coefficient based on time since last update.
    
    Coefficient = min(X * 0.5, MAX_UPDATE_COEFFICIENT), where X = time_diff / 3_months
    """
    current_timestamp = time.time()
    time_diff = current_timestamp - last_update_timestamp
    
    # Calculate X as fraction of 2 months
    x = time_diff / THREE_MONTHS_SECONDS
    
   
    coefficient = max(0.2, min(x * 0.5, MAX_UPDATE_COEFFICIENT))
    
    return coefficient


def calculate_similarity(embedding1: np.ndarray, embedding2: np.ndarray) -> float:
    """Calculate cosine similarity between two embeddings."""
    # Reshape for cosine_similarity which expects 2D arrays
    sim = cosine_similarity(
        embedding1.reshape(1, -1),
        embedding2.reshape(1, -1)
    )[0][0]
    return float(sim)


def update_embedding(
    user_embedding: np.ndarray,
    topic_embedding: np.ndarray,
    coefficient: float
) -> np.ndarray:
    """
    Update user embedding using weighted average.
    
    updated = user_embedding * (1 - coefficient) + topic_embedding * coefficient
    """
    updated = user_embedding * (1 - coefficient) + topic_embedding * coefficient
    # Normalize to maintain unit sphere
    updated = updated / np.linalg.norm(updated)
    return updated


def process_update(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Main function to process embedding update.
    
    Args:
        data: Dictionary containing userEmbedding, newPrompt, lastUpdateTimestamp, lastEmbedding
    
    Returns:
        Dictionary containing updatedEmbedding, skipped, similarity
    """
    try:
        # Validate and extract inputs
        raw_user_embedding = data.get("userEmbedding")
        user_embedding = (
            None
            if raw_user_embedding is None
            else np.array(raw_user_embedding, dtype=np.float32)
        )
        new_prompt = data["newPrompt"]
        last_update_timestamp = float(data["lastUpdateTimestamp"])
        last_embedding = np.array(data["lastEmbedding"], dtype=np.float32)
        
        # Get new embedding for the new prompt
        topic_embedding = model.encode(new_prompt, convert_to_numpy=True)
        topic_embedding = topic_embedding / np.linalg.norm(topic_embedding)
        
        # Calculate similarity between last embedding and new embedding
        similarity = calculate_similarity(last_embedding, topic_embedding)
        
        # Check if similarity is above threshold - if so, skip update
        if similarity >= SIMILARITY_THRESHOLD:
            return {
                "success": True,
                "updatedEmbedding": last_embedding.tolist(),
                "skipped": True,
                "similarity": similarity,
                "reason": f"Similarity {similarity:.4f} exceeds threshold {SIMILARITY_THRESHOLD}"
            }
        
        # Calculate update coefficient based on time
        coefficient = (
            1.0
            if user_embedding is None
            else calculate_update_coefficient(last_update_timestamp)
        )
        
        # Update user embedding using weighted average
        updated_embedding = (
            topic_embedding
            if user_embedding is None
            else update_embedding(user_embedding, topic_embedding, coefficient)
        )
        
        return {
            "success": True,
            "updatedEmbedding": updated_embedding.tolist(),
            "skipped": False,
            "similarity": similarity,
            "updateCoefficient": float(coefficient)
        }
    
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


def main():
    """Main entry point."""
    try:
        # Expect JSON input from stdin or command line argument
        if len(sys.argv) > 1:
            # Read from command line argument
            input_data = json.loads(sys.argv[1])
        else:
            # Read from stdin
            input_data = json.load(sys.stdin)
        
        # Process the update
        result = process_update(input_data)
        
        # Output result as JSON
        print(json.dumps(result))
    
    except json.JSONDecodeError as e:
        print(json.dumps({
            "success": False,
            "error": f"Invalid JSON input: {str(e)}"
        }))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }))


if __name__ == "__main__":
    main()
