namespace :asset do
  namespace :packager do

    desc "Merge and compress assets"
    task :build_all => :environment do
      Synthesis::AssetPackage.build_all
    end

    desc "Delete all asset builds"
    task :delete_all => :environment do
      Synthesis::AssetPackage.delete_all
    end
    
    desc "Generate asset_packages.yml from existing assets"
    task :create_yml => :environment do
      Synthesis::AssetPackage.create_yml
    end
    
  end
end
