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

namespace gstd
{

public class Factory : GLib.Object, FactoryInterface
{
	private GLib.DBusConnection _conn;
	private PipelineInterface[] _pipes;
	private static const int _num_pipes = 20;

	/**
	   Create a new instance of a factory server to process D-Bus
	   factory messages
	 */
	public Factory (GLib.DBusConnection conn)
	{
		_conn = conn;
		_pipes = new PipelineInterface[_num_pipes];
		for (int ids = 0; ids < _pipes.length; ++ids)
		{
			_pipes[ids] = null;
		}
	}

	/**
	   Creates a pipeline from a gst-launch like description using or not
	   debug information
	   @param description, gst-launch like description of the pipeline
	   @param debug, flag to enable debug information
	   @return the dbus-path of the pipeline, or null if out of resources
	 */
	public string create (string description)
	{
		try
		{
			/* Create our pipeline */
			int next_id = 0;
			while (_pipes[next_id] != null)
			{
				next_id = (next_id + 1) % _pipes.length;
				if (next_id == 0)
				{
					return "";
				}
			}
			_pipes[next_id] = new Pipeline (description);

			if (!(_pipes[next_id] as Pipeline).pipeline_is_initialized ())
			{
				_pipes[next_id] = null;
				return "";
			}
			string objectpath = "/com/ridgerun/gstreamer/gstd/pipe" + next_id.to_string ();
			_conn.register_object(objectpath, _pipes[next_id]);
			(_pipes[next_id] as Pipeline).pipeline_set_path(objectpath);
			return objectpath;
		}
		catch (GLib.IOError error)
		{
			return "";
		}
	}

	/**
	   Destroy a pipeline
	   @param id, the pipeline id assigned when created
	   @return true, if succeded
	   @see PipelineId
	 */
	public bool destroy (string objectpath)
	{
		for (int index = 0; index < _pipes.length; ++index)
		{
			if (_pipes[index] != null)
			{
				if ((_pipes[index] as Pipeline).pipeline_get_path () == objectpath)
				{
					_pipes[index] = null;
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
	public bool destroy_all ()
	{
		for (int index = 0; index < _pipes.length; ++index)
		{
			if (_pipes[index] != null)
			{
				_pipes[index] = null;
			}
		}
		return true;
	}

	/**
	   List the existing pipelines
	   @return pipe_list with the corresponding paths
	 */
	public string[] list ()
	{
		string[] paths = {};

		for (int index = 0; index < _pipes.length; ++index)
		{
			if (_pipes[index] != null)
			{
				paths += (_pipes[index] as Pipeline).pipeline_get_path ();
			}
		}
		return paths;
	}

	/**
	   Ping Gstd daemon.
	   Some GStreamer elements use exit(), thus killing the daemon.
	   @return true if alive
	 */
	public bool ping ()
	{
		/*Gstd received the Ping method call */
		return true;
	}
}

}

