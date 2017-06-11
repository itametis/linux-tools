#!/bin/bash
# Licence : GNU/GPL version 3 or (at your option) any later version.
# Auteur : Gaulthier Lallemand




# La longueur minimal et par defaut des clefs ssh
let "SSH_KEY_MIN_LENGTH = 4096"

# La longueur maximale des clefs ssh
let "SSH_KEY_MAX_LENGTH = 8192"

# Le port de la machine distante sur lequel se connecter en ssh
let "SSH_PORT_REMOTE_HOST = 22"

# Le fichier par defaut qui contient les clefs de l'utilisateur
# ~/.ssh/id_rsa contient la clef privee
# ~/.ssh/id_rsa.pub contient la clef publique
DEFAULT_KEY_FILE="/home/$LOGNAME/.ssh/id_rsa"

# Le nom d'utilisateur sur la machine locale
USER_LOCAL_HOST="local_user"

# Le nom d'utilisateur sur la machine distante
USER_REMOTE_HOST="username"

# Le nom ou l'adresse IP de la machine distante
REMOTE_HOSTNAME="hostname"

# Resultat de l'execution de la fonction default_value()
DEFAULT_VALUE=""

# Verifie que ce script n'est pas lance avec les droits root
checkRights() {
	test -w /root;
	if [ "$?" -eq "0" ]; then
		echo "Vous ne devez pas exécuter ce script avec les droits root."
		exit 1
	fi
}

# Demande a l'utilisateur d'appuyer sur ENTREE pour continuer le traitement
pause() {
	echo ""
	read -p "Appuyez sur la touche ENTREE pour continuer." continuer
}

# Bloc d'introduction devant apparaitre au lancement du script
introduction() {
	clear
	echo "        ######################################################"
	echo "        ##                                                  ##"
	echo "        ##                    SSH KeyGen                    ##"
	echo "        ##                                                  ##"
	echo "        ##         GNU/GPL v3  or any later version         ##"
	echo "        ##                                                  ##"
	echo "        ##                                                  ##"
	echo "        ##   Editeur : Gaulthier Lallemand                  ##"
	echo "        ##   Update  : Davy Claisse                         ##"
	echo "        ##                                                  ##"
	echo "        ######################################################"
	echo ""
	echo ""
	echo "Ce script permet de mettre en place une authentification ssh par clef publique. Il doit être lancé"
	echo "sur la machine cliente. Chaque action peut être effectuée séparément. À noter que root ne doit pas"
	echo "exécuter ce script ! "
	echo ""
	echo ""
	echo "La présence du paquet suivant est requise : openssh-client."
	echo ""
	echo "Vous pouvez effectuer les actions suivantes :"
	echo "    - générer une paire de clefs de type RSA et de longueur allant de 4096 a 8192 bits ;"
	echo "    - exporter la clef publique générée sur une machine distante ;"
	echo "    - tester la mise en place de l'authentification par clef."
	echo ""
	echo ""
	echo "Le super utilisateur root ne doit pas exécuter ce script, ce serait pour lui que les clefs seraient"
	echo "générées. La présence du paquet suivant est requise : openssh-client."

	pause
}


# Genere une paire de clefs de type RSA, de taille minimum 4096 bits.
# @param $1 La longueur des nouvelles clefs, de longueur 4096 bits au minimum.
# @param $2 Le path du fichier dans lequel sera ecrite la paire de clefs.
# @return Les fichiers $2 et $2.pub contenant respectivement les clefs privee et publique.
sshGenKeys() {
	if [[ -d $2 ]]
	then
		echo -e "\nErreur rsshkeygen.sshGenKeys(): $2 est un répertoire."
	fi
	if [ $1 -ge "$SSH_KEY_MIN_LENGTH" ] && [ $1 -le "$SSH_KEY_MAX_LENGTH" ]
	then
		ssh-keygen -t rsa -b $1 -f $2
		if [[ -s $2 && -s $2.pub ]]
		then
			echo -e "\nLes clefs ont été générées avec succès."
		else
			echo -e "\nErreur rsshkeygen.sshGenKeys()"
		fi
	else
		echo -e "\nErreur rsshkeygen.sshGenKeys(): $1 n'est pas compris dans l'interval [$SSH_KEY_MIN_LENGTH - $SSH_KEY_MAX_LENGTH]."
	fi
}

# Transfert le fichier $2 depuis la machine courante vers le fichier ~/.ssh/authorized_keys d'une
# machine distante.
# @param $1 Le port ssh de la machine distante.
# @param $2 Le fichier a exporter vers la machine distante.
# @param $3 Le nom d'utilisateur sur la machine distante.
# @param $4 Le nom ou l'adresse IP de la machine distante.
# @return Le fichier authorized_keys dans /home/$3/.ssh/ sur la machine $4 via le port $1
scpFileUp() {
	port=$1
	file=$2
	user=$3
	host=$4
	public_key=`cat $file`

	echo -e "\nEntrez votre mot de passe pour la session distante :"
#	ssh -q $1 "mkdir ~/.ssh 2>/dev/null; chmod 700 ~/.ssh; echo "$KEYCODE" >> ~/.ssh/authorized_keys; chmod 644 ~/.ssh/authorized_keys"
#	scp -P $1 $2 $3@$4:/home/$3/.ssh/authorized_keys
	ssh -q -p $port $user@$host "mkdir ~/.ssh 2>/dev/null; chmod 700 ~/.ssh; echo "$public_key" >> ~/.ssh/authorized_keys; chmod 644 ~/.ssh/authorized_keys"
}
## A ce moment il peut vous etre demande votre passphrase du trousseau de connexion.

# Teste que la connection par clef publique fonctionne sur la machine distante specifiee.
# @param /
# @return Un message sur la sortie standard indiquant si la connection fonctionne ou non.
sshConnexionTest() {
	scp -P $SSH_PORT_REMOTE_HOST "$USER_REMOTE_HOST@$REMOTE_HOSTNAME:~/.ssh/authorized_keys" ~/testco.tmp
	if [[ -s ~/testco.tmp ]]
	then
		echo -e "\nConnection établie avec succes."
	else
		echo -e "\nLa connection a echoué."
	fi
	rm -f ~/testco.tmp
}

# Affecte une valeur par defaut a la variable DEFAULT_VALUE si l'utilisateur tape ENTREE.
# @param $1: texte a afficher (sans les ':')
# @param $2: valeur par defaut.
# @return DEFAULT_VALUE, contenant la valeur choisie par l'utilisateur ou la valeur par defaut.
default_value() {
	local var_1=""
	read -p "$1 ($2): " var_1
	if [[ $var_1 = "" ]]
	then
		DEFAULT_VALUE="$2"
	else
		DEFAULT_VALUE="$var_1"
	fi
}

#######################
# Execution du script #
#######################
introduction
checkRights
clear
let "choice = -1"
while [ ! $choice -eq 0 ];
do
	echo ""
	echo "        ######################################################"
	echo "        ##                                                  ##"
	echo "        ##                     Actions                      ##"
	echo "        ##                                                  ##"
	echo "        ######################################################"
	echo ""
	echo ""
	echo -e "\nChoisissez une action parmi celles-ci :"
    echo "     [0] - Quitter ce script."
	echo "     [1] - Générer une paire de clefs RSA."
	echo "     [2] - Exporter la clef publique vers une machine distante."
	echo "     [3] - Vérifier l'authentification par clef publique."
	echo ""
	read -p "Action a effectuer: " choice

	case "$choice" in
		'1')
			clear
			echo "        ######################################################"
			echo "        ##                                                  ##"
			echo "        ##                  Génération des                  ##"
			echo "        ##                    clefs SSH                     ##"
			echo "        ##                                                  ##"
			echo "        ######################################################"
			echo ""
			echo ""
			default_value "Entrez la longueur des clefs a generer" $SSH_KEY_MIN_LENGTH
			let "keysize_tmp = $DEFAULT_VALUE"
			default_value "Entrez le fichier dans lequel exporter les clefs" $DEFAULT_KEY_FILE
			sshGenKeys $keysize_tmp $DEFAULT_VALUE
		;;
		'2')
			clear
			echo "        ######################################################"
			echo "        ##                                                  ##"
			echo "        ##              Exportation de la clef              ##"
			echo "        ##        publique vers une machine distante        ##"
			echo "        ##                                                  ##"
			echo "        ######################################################"
			echo ""
			echo ""
			default_value "Saisissez le numéro de port SSH de la machine distante" $SSH_PORT_REMOTE_HOST
			SSH_PORT_REMOTE_HOST=$DEFAULT_VALUE
			default_value "Saisissez le nom complet du fichier devant être exporté" "$DEFAULT_KEY_FILE.pub"
			key_file_tmp="$DEFAULT_VALUE"
			default_value "Saisissez le nom de l'utilisateur de la machine distante" $USER_REMOTE_HOST
			USER_REMOTE_HOST="$DEFAULT_VALUE"
			default_value "Saisissez le nom ou l'adresse IP de la machine distante" $REMOTE_HOSTNAME
			REMOTE_HOSTNAME=$DEFAULT_VALUE
			scpFileUp $SSH_PORT_REMOTE_HOST $key_file_tmp $USER_REMOTE_HOST $REMOTE_HOSTNAME
		;;
		'3')
			clear
			echo "        ######################################################"
			echo "        ##                                                  ##"
			echo "        ##                Vérification de la                ##"
			echo "        ##              connexion par clefs SSH             ##"
			echo "        ##                                                  ##"
			echo "        ######################################################"
			echo ""
			echo ""
			default_value "Saisissez le numéro de port SSH de la machine distante" $SSH_PORT_REMOTE_HOST
			SSH_PORT_REMOTE_HOST=$DEFAULT_VALUE
			default_value "Saisissez le nom de l'utilisateur de la machine distante" $USER_REMOTE_HOST
			USER_REMOTE_HOST="$DEFAULT_VALUE"
			default_value "Saisissez le nom ou l'adresse IP de la machine distante" $REMOTE_HOSTNAME
			REMOTE_HOSTNAME="$DEFAULT_VALUE"
			sshConnexionTest
		;;
		'0')
			echo -e "\n     ### FiN DU SCRiPT ###"
			exit 0
		;;
		*)
			echo -e "\n### Choisissez un chiffre entre 0 et 4 ! ###"

	esac

done
