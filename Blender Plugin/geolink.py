import sys
import os
import bmesh

bl_info = {
    "name": "Geometry Link",
    "blender": (2, 80, 0),
    "category": "Object",
    "version": (1, 0, 0),
    "author": "Danilo Campos",
    "description": "Monitors geometry changes and serializes them to JSON",
}

import bpy
import json
from bpy.app.handlers import depsgraph_update_post
import network

import json
import bmesh

import os
import tempfile
import base64

is_updating = False

def serialize_geometry(obj):
    # Ensure the object is a mesh
    if obj.type != 'MESH':
        return None
    
    

    # Use Blender's temporary directory to store the temporary file
    temp_dir = bpy.app.tempdir
    temp_file_path = os.path.join(temp_dir, "temp_usd_file.usd")

    # Export the selected object to the temporary USD file
    bpy.ops.wm.usd_export(filepath=temp_file_path, selected_objects_only=True)

    # Read the temporary file into memory
    with open(temp_file_path, "rb") as file:
        usd_data = file.read()

    # Optionally convert to base64 for easier transmission over certain network protocols
    base64_usd = base64.b64encode(usd_data).decode('utf-8')

    # Clean up by deleting the temporary file
    #os.remove(temp_file_path)

    return base64_usd

def geometry_update_handler(scene):
    global is_updating

    # Check if the handler is already running to prevent recursion
    if is_updating:
        return

    # Set the lock
    is_updating = True

    try:
        active_obj = bpy.context.view_layer.objects.active
        if active_obj:
            geometry_json = serialize_geometry(active_obj)
            if geometry_json:
                print("attempting transmission")
                network.broadcast_geometry_update(geometry_json)
    finally:
        # Release the lock
        is_updating = False

def register():
    print("Registering")
    depsgraph_update_post.append(geometry_update_handler)
    network.start_server()  # Start the TCP server

def unregister():
    print("Unregistering")
    network.stop_server()
    depsgraph_update_post.remove(geometry_update_handler)