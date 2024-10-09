# 🚀 Paiement par CinetPay 👋
![Pub Version](https://img.shields.io/pub/v/cinetpay) ![Relative date](https://img.shields.io/date/1638525600) ![Pub Score](https://img.shields.io/pub/points/cinetpay) ![Pub Like](https://img.shields.io/pub/likes/cinetpay) ![Pub Like](https://img.shields.io/pub/popularity/cinetpay)

[![CinetPay Logo](https://imgur.com/WxqeWOL.png)](https://cinetpay.com)

> Ce package vous permet d'invoquer le **guichet de paiement de CinetPay**, effectuer un paiement et attendre le statut du paiement initié à la seconde près après la fin du paiement

## 🔗 Les étapes
L'utilisation du package est la plus simple possible, dans son utilisation, il s'agit d'invoquer celui-ci avec :
- `Les paramétres d'initialisation du guichet`
- `Les données relatives au paiement`
- `Le callback d'attente du retour de paiement`
- `Le callback d'écoute d'erreur d'exécution`

## 🛠 Les prérequis
Quelques prérequis sont nécessaires pour faire fonctionner correctement le package.

 - #### Android

    - Ajouter les permissions suivantes dans le fichier **_android/app/src/main/AndroidManifest.xml_** 
    
        ```xml
            <application
            	...
                android:usesCleartextTraffic="true">
                ...
            </application>
            ...
            <uses-permission android:name="android.permission.INTERNET"/>
        ```
    - Modifier la version du **_minSdkVersion_** dans le fichier **_android/app/src/build.gradle** 
        > `minSdkVersion 17`
        
 - #### IOS
   - Ajouter la permission suivante dans le fichier **_ios/Runner/Info.plist_**
   
        ```plist
            <key>NSAppTransportSecurity</key>
            <dict>
                <key>NSAllowsArbitraryLoads</key>
                <true/>
            </dict>
        ```

## Initialisation du guichet
Pour fonctionner, le guichet doit impérativement recevoir des données telles que :

- _**apikey**_ | L’identifiant du marchand | Chaine de caractère | `Obligatoire`
- _**site_id**_ | L'identifiant du service | Entier | `Obligatoire`
- _**notify_url**_ | URL de notification de paiement valide | URL | `Obligatoire`

## Données du paiement
Pour effectuer le paiement, certaines données devront-être sousmises pour préparer le guichet. Ainsi, on a :

- _**amount**_ | Montant du paiement `(>= 100 XOF)` | Entier | `Obligatoire`
- _**currency**_ | Devise du paiement (`XOF` - `XAF` - `CDN` - `GNF` - `USD`) | Chaîne de caractère | `Obligatoire`
- _**transaction_id**_ | L'identifiant de la transaction. Elle doit-être unique, pour chaque transaction | Chaîne de caractère | `Obligatoire`
- _**description**_ | La description de votre paiement | Chaîne de caractère | `Obligatoire`
- _**channels**_ | L’univers de paiement. Peut être : `ALL` - `MOBILE_MONEY` - `WALLET`. Par défaut : `'ALL'`  Toute combinaison est applicable à en séparant par une virgule : `'MOBILE_MONEY, WALLET'` | Chaîne de caractère | Facultatif
- _**metadata**_ |  | Chaîne de caractère | Facultatif

## Callback de retour de paiement
Lorsque le paiement est enclenché, le package reste en attente du statut final du paiement-ci. Ainsi, à la fin du paiement le package reçoit le statut, qu'il le transmet au travers du callback qui sera définit. Le format de retour attendu est le suivant :

- _**amount**_ | Montant du paiement | Entier
- _**currency**_ | Devise du paiement | Chaîne de caractère
- _**status**_ | Statut du paiement (`ACCEPTED` ou `REFUSED)` | Chaîne de caractère
- _**payment_method**_ | Moyen du paiement | Chaîne de caractère
- _**description**_ | La description de votre paiement | Chaîne de caractère
- _**metadata**_ | Chaîne de caractère
- _**operator_id**_ | L'identifiant du paiement de l'opérateur | Chaîne de caractère
- _**payment_date**_ | La date du paiement | Chaîne de caractère

## Callback d'erreur de traitement
Lors du traitement, il peut survenir certains types d'erreurs telles que, _certains paramètres pour le paiement manquantes_. Le format de retour attendu est le suivant :

- _**message**_ | Chaîne de caractère
- _**description**_ | Chaîne de caractère

## 👩‍💻 Utilisation du package
En resumé, le package s'utilise par le biais d'un appel appel widget :
```dart
CinetPayCheckout(
    title: 'YOUR_TITLE',
    titleStyle: YOUR_TITLE_STYLE,
    titleBackgroundColor: YOUR_TITLE_BACKGROUND_COLOR,
    configData: <String, dynamic> {
        'apikey': 'YOUR_API_KEY',
        'site_id': YOUR_SITE_ID,
        'notify_url': 'YOUR_NOTIFY_URL'
    },
    paymentData: <String, dynamic> {
        'transaction_id': 'YOUR_TRANSACTION_ID',
        'amount': 100,
        'currency': 'XOF',
        'channels': 'ALL',
        'description': 'YOUR_DESCRIPTION'
    },
    waitResponse: (response) {
        print(response);
    }
    onError: (error) {
        print(error);
    }
);
```

![CinetPay Checkout](https://i.imgur.com/gQZGV1l.png)

## 😄 Auteur
Agbetogor Germain ([@Germinator](https://germinator-space.com))