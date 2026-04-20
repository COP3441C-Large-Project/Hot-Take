ML based matchmaking.





update.py gets input (Userprofile, newPrompt, lastUpdatedTime, lastEmbedding),

output updated user representation, whether update was skipped, and similarity between previos and current topic embedding



updateEmbedding.js is a wrapper that calls update.py. It can be used as a reference, basis or component for the API endpoint that updates user and scans for matches. Logic for the latter needs implementation, in node. 

This version is running on hardcoded input.  updateEmbedding.js should pull input values from cached user memory.



To run locally:


* create an env with python 3.11
* Have a node runtime installed
* pip install requirements.txt
* run embedding.js









