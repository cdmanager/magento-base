<?php

class MagentoInstaller
{
    private $magentoCli;
    private $dbHost;
    private $dbUser;
    private $dbPassword;
    private $dbName;

    public function __construct()
    {
        $this->magentoCli = '/var/www/html/bin/magento';
        $this->dbHost = getenv('DB_HOST');
        $this->dbUser = getenv('DB_USER');
        $this->dbPassword = getenv('DB_PASSWORD');
        $this->dbName = getenv('DB_NAME');
    }

    public function installMagento()
    {
        echo "Running Magento Install Script...\n";
        $installCommand = [
            "{$this->magentoCli} setup:install",
            "--base-url=" . getenv('MAGENTO_URL'),
            "--base-url-secure=" . getenv('MAGENTO_URL_SECURE'),
            "--db-host={$this->dbHost}",
            "--db-name={$this->dbName}",
            "--db-user={$this->dbUser}",
            "--db-password={$this->dbPassword}",
            "--backend-frontname=" . getenv('ADMIN_URL_PREFIX'),
            "--admin-firstname=Admin",
            "--admin-lastname=User",
            "--admin-email=" . getenv('ADMIN_EMAIL'),
            "--admin-user=" . getenv('ADMIN_USERNAME'),
            "--admin-password=" . getenv('ADMIN_PASSWORD'),
            "--language=en_US",
            "--currency=USD",
            "--timezone=America/New_York",
            "--use-rewrites=1",
            "--search-engine=elasticsearch7",
            "--elasticsearch-host=" . getenv('ES_HOST')
        ];
        system(implode(' ', $installCommand));
        echo "Magento installation completed.\n";
    }

    public function flushCache()
    {
        echo "Flushing cache...\n";
        system("{$this->magentoCli} cache:clean");
        system("{$this->magentoCli} cache:flush");
        echo "Cache flushed successfully.\n";
    }

    public function copyThumbnailFile()
    {
        $thumbnailFile = "/var/www/html/vendor/magento/module-catalog/Ui/Component/Listing/Columns/Thumbnail.php";
        $thumbnailPhpFile = "Thumbnail.php";
        echo "Copying the updated Thumbnail.php file to the appropriate location...\n";
        copy($thumbnailPhpFile, $thumbnailFile);
    }

    public function run()
    {
            echo "Installing Magento...\n";
            $this->installMagento();
            $this->flushCache();
            $this->copyThumbnailFile();
            echo "Magento installation completed.\n";
        
    }
}

$installer = new MagentoInstaller();
$installer->run();
