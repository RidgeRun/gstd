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

	/**
	   Create a new instance of a factory server to process D-Bus
	   factory messages
	 */
	public Factory (GLib.DBusConnection conn)
	{
		_conn = conn;
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
			/* create GStreamer pipe */
			Pipeline pipe = new Pipeline (description, _conn);
			return pipe.path;
		}
		catch (GLib.Error error)
		{
			return "";
		}
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
