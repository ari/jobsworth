/**
 * The "classic" theme markup for Shadowbox.
 *
 * This file is part of Shadowbox.
 *
 * Shadowbox is an online media viewer application that supports all of the
 * web's most popular media publishing formats. Shadowbox is written entirely
 * in JavaScript and CSS and is highly customizable. Using Shadowbox, website
 * authors can showcase a wide assortment of media in all major browsers without
 * navigating users away from the linking page.
 *
 * Shadowbox is released under version 3.0 of the Creative Commons Attribution-
 * Noncommercial-Share Alike license. This means that it is absolutely free
 * for personal, noncommercial use provided that you 1) make attribution to the
 * author and 2) release any derivative work under the same or a similar
 * license.
 *
 * If you wish to use Shadowbox for commercial purposes, licensing information
 * can be found at http://mjijackson.com/shadowbox/.
 *
 * @author      Michael J. I. Jackson <mjijackson@gmail.com>
 * @copyright   2007-2008 Michael J. I. Jackson
 * @license     http://creativecommons.org/licenses/by-nc-sa/3.0/
 * @version     SVN: $Id: skin.js 108 2008-07-11 04:19:01Z mjijackson $
 */

if(typeof Shadowbox == 'undefined'){
    throw 'Unable to load Shadowbox skin, base library not found.';
}

/**
 * The HTML markup to use for Shadowbox.
 *
 * IMPORTANT: The script depends on most of these elements being present.
 *
 * @property    {Object}    SKIN
 * @public
 * @static
 */
Shadowbox.SKIN = {

    markup:     '<div id="shadowbox_container">' +
                    '<div id="shadowbox_overlay"></div>' +
                    '<div id="shadowbox">' +
                        '<div id="shadowbox_title">' +
                            '<div id="shadowbox_title_inner"></div>' +
                        '</div>' +
                        '<div id="shadowbox_body">' +
                            '<div id="shadowbox_body_inner"></div>' +
                            '<div id="shadowbox_loading">' +
                                '<div id="shadowbox_loading_indicator"></div>' +
                                '<span><a onclick="Shadowbox.close();">{cancel}</a></span>' +
                            '</div>' +
                        '</div>' +
                        '<div id="shadowbox_info">' +
                            '<div id="shadowbox_info_inner">' +
                                '<div id="shadowbox_counter"></div>' +
                                '<div id="shadowbox_nav">' +
                                    '<a id="shadowbox_nav_close" title="{close}" onclick="Shadowbox.close()"></a>' +
                                    '<a id="shadowbox_nav_next" title="{next}" onclick="Shadowbox.next()"></a>' +
                                    '<a id="shadowbox_nav_play" title="{play}" onclick="Shadowbox.play()"></a>' +
                                    '<a id="shadowbox_nav_pause" title="{pause}" onclick="Shadowbox.pause()"></a>' +
                                    '<a id="shadowbox_nav_previous" title="{previous}" onclick="Shadowbox.previous()"></a>' +
                                '</div>' +
                                '<div class="shadowbox_clear"></div>' +
                            '</div>' +
                        '</div>' +
                    '</div>' +
                '</div>',

    png_fix:    [
        'shadowbox_nav_close',
        'shadowbox_nav_next',
        'shadowbox_nav_play',
        'shadowbox_nav_pause',
        'shadowbox_nav_previous'
    ]

};
