<?php

$databases['default']['default']['database'] = getenv('DB_NAME');
$databases['default']['default']['username'] = getenv('DB_USER');
$databases['default']['default']['password'] = getenv('DB_PASSWORD');
$databases['default']['default']['host'] = getenv('DB_HOST');
$databases['default']['default']['port'] = getenv('DB_PORT');
$databases['default']['default']['driver'] = 'mysql';
$databases['default']['default']['isolation_level'] = 'READ COMMITTED';
$settings['hash_salt'] = '2c4951052dec2b03fae5c874916652cf6c5239f27f56f37d9fb5f97414eef532';
$settings['config_sync_directory'] = '../config/sync';
$settings['file_private_path'] = '../private';
$settings['trusted_host_patterns'] = [getenv('DP_HOSTNAME') ?: '.*'];
$settings['testing_package_manager'] = TRUE;
