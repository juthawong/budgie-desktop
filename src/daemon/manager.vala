/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

/**
 * Main lifecycle management, handle all the various session and GTK+ bits
 */
public class ServiceManager : GLib.Object
{
    private string? current_theme_uri;
    private Settings? settings;
    private Budgie.ThemeManager theme_manager;
    /* Keep track of our SessionManager */
    private LibSession.SessionClient? sclient;

    /* On Screen Display */
    Budgie.OSDManager? osd;

    /**
     * Construct a new ServiceManager and initialiase appropriately
     */
    public ServiceManager()
    {
        theme_manager = new Budgie.ThemeManager();
        register_with_session.begin((o,res)=> {
            bool success = register_with_session.end(res);
            if (!success) {
                message("Failed to register with Session manager");
            }
        });
        osd = new Budgie.OSDManager();
        osd.setup_dbus();
    }

    /**
     * Attempt registration with the Session Manager
     */
    private async bool register_with_session()
    {
        try {
            sclient = yield LibSession.register_with_session("budgie-daemon");
        } catch (Error e) {
            return false;
        }

        sclient.QueryEndSession.connect(()=> {
            end_session(false);
        });
        sclient.EndSession.connect(()=> {
            end_session(false);
        });
        sclient.Stop.connect(()=> {
            end_session(true);
        });
        return true;
    }

    /**
     * Properly shutdown when asked to
     */
    private void end_session(bool quit)
    {
        if (quit) {
            Gtk.main_quit();
            return;
        }
        try {
            sclient.EndSessionResponse(true, "");
        } catch (Error e) {
            warning("Unable to respond to session manager! %s", e.message);
        }
    }
} /* End ServiceManager */


} /* End namespace Budgie */
