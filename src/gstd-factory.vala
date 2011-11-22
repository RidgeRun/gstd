/*
 * gstd/src/gstd-factory.vala
 *
 * GStreamer daemon pipeline Factory class - framework for controlling audio and video streaming using D-Bus messages
 *
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
 *
 * GPL2 license - See http://www.opensource.org/licenses/gpl-2.0.php for complete text.
 */
using Gst;

[DBus (name = "com.ridgerun.gstreamer.gstd.FactoryInterface")]
public class Factory : GLib.Object
{
	private Pipeline[] pipes;
	private static const int num_pipes = 20;

	/**
	   Create a new instance of a factory server to process D-Bus
	   factory messages
	 */
	public Factory ()
	{
		this.pipes = new Pipeline[this.num_pipes];
		for (int ids = 0; ids < this.pipes.length; ids++)
		{
			this.pipes[ids] = null;
		}
	}

	/**
	   Creates a pipeline from a gst-launch like description using or not
	   debug information
	   @param description, gst-launch like description of the pipeline
	   @param debug, flag to enable debug information
	   @return the dbus-path of the pipeline, or null if out of resources
	 */
	public string Create (string description)
	{
		/* Create our pipeline */
		int next_id = 0;
		while (this.pipes[next_id] != null)
		{
			next_id = (next_id + 1) % this.pipes.length;
			if (next_id == 0)
			{
				return "";
			}
		}
		this.pipes[next_id] = new Pipeline (description);

		if (!this.pipes[next_id].PipelineIsInitialized ())
		{
			this.pipes[next_id] = null;
			return "";
		}
		string objectpath =
		    "/com/ridgerun/gstreamer/gstd/pipe" + next_id.to_string ();
		conn.register_object (objectpath, this.pipes[next_id]);
		this.pipes[next_id].PipelineSetPath (objectpath);
		return objectpath;
	}

	/**
	   Destroy a pipeline
	   @param id, the pipeline id assigned when created
	   @return true, if succeded
	   @see PipelineId
	 */
	public bool Destroy (string objectpath)
	{
		for (int index = 0; index < this.pipes.length; index++)
		{
			if (this.pipes[index] != null)
			{
				if (this.pipes[index].PipelineGetPath () == objectpath)
				{
					this.pipes[index] = null;
					return true;
				}
			}
		}

		Posix.syslog (Posix.LOG_ERR, "Fail to destroy pipeline");
		return false;
	}
	
	/**
	   Destroy all pipelines
	   @return true, if succeded
	   @see PipelineId
	 */
	public bool DestroyAll ()
	{
		for (int index = 0; index < this.pipes.length; index++)
		{
			if (this.pipes[index] != null)
			{
				this.pipes[index] = null;
			}
		}
		return true;
	}

	/**
	   List the existing pipelines
	   @return pipe_list with the corresponding paths
	 */
	public string[] List ()
	{
		string[] paths = {};

		for (int index = 0; index < this.pipes.length; ++index)
		{
			if (this.pipes[index] != null)
			{
				paths += this.pipes[index].PipelineGetPath ();
			}
		}
		return paths;
	}

	/**
	   Ping Gstd daemon.
	   Some GStreamer elements use exit(), thus killing the daemon.
	   @return true if alive
	 */
	public bool Ping ()
	{
		/*Gstd received the Ping method call */
		return true;
	}
}

