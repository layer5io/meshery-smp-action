MESH=$1

echo "Checking if mesheryctl is installed"
	
if mesheryctl
	
then
	echo found mesheryctl, deploying $MESH
	mesheryctl mesh deploy $MESH
	
else
	printf "Mesheryctl not found. \nInstalling...\n"
	install_mesheryctl
	echo "Installed mesheryctl successfully!"
	mesheryctl mesh deploy $MESH
	
fi





install_mesheryctl(){
  curl -L https://github.com/meshery/meshery/releases/download/v0.5.67/mesheryctl_0.5.67_Linux_x86_64.zip -o mesheryctl.zip
  unzip -n mesheryctl.zip 
  mv mesheryctl /usr/local/bin/mesheryctl
}
