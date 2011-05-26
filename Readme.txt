Courseplay - Abfahrhelfer f�r LS 2011 v 2.1

Inhaltsverzeichnis

I. Changelog
II.   Installationsanweisung
III.  Bedienungsanleitung
IV. Credits
V. Videos

Ia. Changelog - �nderungen seit Version 2.0
	In der Version 2.0 waren leider noch einige Fehler die den Multiplayermodus gest�rt haben. Diese wurden behoben.
	Neu in dieser Version ist vor allem, dass ihr eure Schlepper nicht mehr mit courseplay nachr�sten m�sst. Einfach den Mod ins Modverzeichnis und alle Fahrzeuge sind automatisch damit ausgestattet.
	Durch diese �nderung m�sst ihr leider in allen bereits umger�steten Schleppern den Eintrag "<specialization name="courseplay" />" entfernen.
	Weiterhin wurde in dieser Version das Kombinieren von Kursen verbessert.
	
	Wichtig: die Datei aaacourseplay.zip (v2 und kleiner) MUSS aus dem Mod-Verzeichnis gel�scht werden.

Ib. Changelog - �nderungen seit Version 1.6

	Die gr��te �nderung im courseplay ist nat�rlich die Multiplayerf�higkeit. Dabei werden beim Spielstart alle Werte und sogar gespeicherte Kurse vom Host an die Clients �bertragen. Das kann mitunter ein bisschen dauern ist aber notwendig.
	Neben zahlreichen Bugfixes und Performance-Optimierungen die hier nicht weiter erw�hnt werden sollen gibt es im wesentlichen die folgende Neuerungen:

	Kursverwaltung: Gespeicherte Kurse werden jetzt alphabetisch sortiert und werden immmer global f�r alle Fahrzeuge gespeichert. Dadurch ist kein Synchronisieren der Kurse zwischen den einzelnen Fahrzeugen mehr n�tig und der Speicherverbrauch ist drastisch gesunken.

	Kurse aufnhemen: Das Pausieren der Kursaufnahme wurde �berarbeitet. Man kann jetzt die Kursaufzeichnung pausieren und die letzten Wegpunkte l�schen. Dabei wird jetzt immer nur der letzte Wegpunkt angezeigt und nicht mehr alle.

	Neu: Kurs Offset

	Dieses Feature ist noch experimentell und soll daf�r sorgen, dass der Schlepper den gespeicherten Kurs leicht versetzt abf�hrt. Gedacht ist dies zum Beispiel f�r Ballensammelwagen.

	Neue Kurskombination:

	Ihr k�nnt beim Einfahren eines Kurses jetzt Kreuzungspunkte setzen. Wenn ihr sp�ter mehrere Kurse hintereinander ladet werden diese immer am ersten gemeinsamen Kreuzungspunkt (Abstand unter 30 Metern!) zusammengef�gt. Damit k�nnt ihr also auch Teile von Routen wieder verwenden.

	Das R�ckw�rtsfahren wurden optimiert und sollte jetzt wieder richtig funktionieren.

	Wenn ihr das Spiel speichert werden die Einstellungen eurer Abfahrer mit gespeichert. Nach dem Neuladen m�sst ihr also normalerweise nichts mehr einstellen. Die zuvor geladenen Kurse und Einstellungen sollten komplett wieder verf�gbar sein.

	Au�erdem gibt es neue Symbole f�r die Wegpunkte und spezielle Wegpunkte wie Kreuzungspunkte und Startpunkte sind auch sichtbar wenn ihr nicht im Fahrzeug seid welches die Route gespeichert hat.


Ic. Changelog - �nderungen seit Version 1.2

	Neu hinzugekommen sind vor allem der Feldmodus mit dem man Ballen pressen und Heusammeln kann. Der G�llemodus wurde weiter perfektioniert und es ist jetzt auch m�glich den Abfahrhelfer in Drescher und H�cksler einzubauen.
	Damit kann man beispielsweise mit Dreschern im Helfermodus Kurse aufzeichnen lassen die man dann sp�ter f�r den G�lle- oder Feldmodus ver�ndern kann.
	Zudem gibt es eine Steuerung des Abfahrhelfers aus dem Drescher heraus. Man kann einen Abfahrhelfer rufen, starten, stoppen und beim H�cksler die Seite des Abfahrers �ndern.
	Beim Abfahrhelfer kann man jetzt einstellen bei wieviel Prozenz F�llstand er fr�hzeitig abfahren soll. Hat ein Abfahrer zum Beispiel einen F�llstand von 90% und der Drescher wendet am Ende des Feldes, f�hrt der Abfahrer gleich ab und wartet nicht auf das Wendeman�ver.
	Zudem f�hrt der �berladewagen an seinem �berladepunkt wieder zur�ck aufs Feld wenn er einen gewissen F�llstand unterschritten hat und f�r etwa 20 Sekunden kein weiterer Abfahrer zum �berladen konmmt.
	Au�erdem wurrde gew�nscht, dass der Abfahrhelfer auf der Stra�e seine Rundumleuchte einschaltet - das tut er jetzt ;)
	Dann gab es nat�rlich auch noch etwas Feintuning: Das unsinnige Kreiseln auf dem Feld sollte jetzt vorbei sein, HW80 Drehschemel und Agroliner Container werden jetzt auch unterst�tzt. 


Id. Changelog - �nderungen seit Version 1.0

	Als neue Funktionen sind im wesentlichen der D�ngemodus und das R�ckw�rtsfahren hinzugekommen. Au�erdem wurde das Fahrverhalten (besonders in Kurven) verbessert und es werden mehr EntladeTrigger (Gras und Silage) erkannt.
	Zudem kann man jetzt gespeicherte Kurse kombinieren indem man mehrere Kurse hintereinander l�dt. Wenn man nur einen neuen Kurs laden will muss man allerdings jetzt vorher die Wegpunkte des alten zur�cksetzen.
	Au�erdem ist der Abfahrhelfer jetzt kein "hireable" mehr, das hei�t er verbraucht jetzt Benzin(D�nger..) beim Fahren. Damit der Abfahrer nicht einfach irgendwo stehen bleibt bekommt man eine Warnung sobald der Tank fast leer ist und bei einem minimalen Tankinhalt bleibt der Abfahrhelfer stehen damit man ihn noch bis zur Zapfs�ule bekommt.
	Im Menu wurde noch der "BUG" behoben, dass man das Menu mit allen Maustasten steuern konnte.
	Nat�rlich gab es noch viele weitere kleine Bugfixes.

	Dieses Mal geht ein besonders gro�er Dank an Wolverine, der einen Gro�teil dieses Updates (D�ngemodus und R�ckw�rtsfahren) implementiert hat.
	Wir haben weiterhin an einer Version 2 die komplett multiplayerf�hig ist, die aktuelle Version 1.20 ist aber zumindest im MP vom Host bedienbar.



II. Installationsanweisung

1. Das Archiv ZZZ_courseplay.zip in das Verzeichnis C:\Users\dein Username\MyGames\FarmingSimulator2011\mods kopieren. Das War es!


III. Bedienungsanleitung


	Steuerung:

		Die Steuerung des Abfahrhelfers funktioniert im wesentlichem mit der Maus da freie Tasten im Landwirtschafts Simulator ja sehr rah sind.
		Mit einem Klick auf die rechte Maustaste aktiviert ihr das Courseplay HUD in dem ihr den Abfahrer konfigurieren k�nnt. Zus�tzlich sind einige Funktionen wie Abfahrer starten und stoppen auch �ber die Tastatur �ber die Tasten NUMPAD 7 bis NUMPAD 9 belegt.

	HUD:

		Wenn ihr das HUD �ffnet wird automatisch die Maussteuerung aktiviert. Das hei�t ihr k�nnt euch mit der Maus nicht mehr umgucken. Um die Maussteuerung zu deaktivieren m�sst ihr einfach nochmal auf die rechte Maustaste klicken.
		Alternativ k�nnt ihr auch auf das rote X oben rechts im HUD klicken. Dabei wird das HUD geschlossen und die Maussteuerung wieder deaktiviert.

		Das HUD ist in mehrere Unterseiten unterteilt. Diese k�nnt ihr mit den blauen Pfeilen im oberen Bereich des HUDs wechseln.
		Im mittleren Bereich des HUDs k�nnt ihr auf jeder Unterseite verschiede Einstellungen vornehmen oder Befehle geben. Klickt dazu einfach auf die gew�nschte Aktion.

		Im unteren Bereich des HUDs findet ihr Infos �ber euren Abfahrer den geladenen Kurs und den aktuellen Status. Dort k�nnt ihr durch klick auf die Diskette euren eingefahrenen Kurs auch speichern.

	HUD "Abfahrhelfer Steuerung":

		Kursaufzeichnung beginnen:

			Mit dieser Option wird der Aufnahmemodus des Abfahrhelfers aktiviert. Ihr k�nnt damit den Kurs einfahren den der Abfahrer sp�ter fahren soll.
			Bei Aktivierung werden anfangs drei F�sschen im Abstand von 10-20 Metern gesetzt. Ihr solltet darauf achten, dass ihr bis zum dritten Fass nach M�glichkeit geradeaus fahrt.
			Wenn ihr diese Funktion aktiviert habt k�nnt ihr mit der rechten Maustaste die Maussteuerung deaktivieren damit ihr euch beim Einfahren des Kurses auch umschauen k�nnt.

		Kursaufzeichnung anhalten:

			Wenn die Kursaufzeichnung l�uft k�nnt ihr mit dieser Funktion die Kursaufzeichnung pausieren. Es wird ein gelber Pfeil angezeigt der zum letzten Wegpunkt zeigt. Zus�tzlich k�nnt ihr in diesem Modus auch den letzten Wegpunkt l�schen.

		Kursaufzeichnung beenden:

			Diese Aktion ist nur im Aufnahmemodus verg�gbar und dient dazu diesen zu beenden. Klickt auf diese Funktion wenn ihr den Endpunkt eurer eingefahrenen Route erreicht habt.
			Es empfiehlt sich, dass der Endpunkt etwa 10 Meter vor dem Startpunkt liegt und dass man grob aus der Richtung kommt in die der Abfahrer beim Startpunkt auch weiterfahren soll.

		Hier Wartepunkt setzen:

			Im Aufnahmemodus habt ihr die M�glichkeit auf der Strecke Wartepunkte zu setzen. An diesen Punkten wird der Abfahrer sp�ter beim Abfahren anhalten bis man ihn manuell weiter schickt.
			Wenn ein Abfahrer einen Wartepunkt erreicht hat wird euch das am unteren Bildschirmrand angezeigt.

		Abfahrer einstellen:

			Wenn ihr einen Kurs eingefahren habt k�nnt ihr jetzt den Abfahrer einstellen. Dabei wird der Abfahrhelfer aktiviert und f�hrt brav seine Route ab.

		Abfahrer entlassen:

			Den aktivierten Abfahrer k�nnt ihr nat�rlich auch jederzeit entlassen bzw. anhalten.
			Wenn ihr den Abfahrhelfer sp�ter wieder aktiviert wird er seine Route am letzen Punkt fortf�hren.

		weiterfahren:

			Diese Option steht euch zur Verf�gung wenn der Abfahrer einen Wartepunkt erreicht hat.

		Abfahrer-Typ wechseln:

			Damit der Abfahrhelfer m�glichst viele Aufgaben erledigen kann gibt es verschiedene Abfahrhelfer Typen.
			Der aktuelle Typ wird im unteren Bereich des HUDs angezeigt. Mit klick auf diese Aktion k�nnt ihr die Typen durchgehen.

			Typ: Abfahrer

				Der Typ Abfahrer wartet am Startpunkt bis er voll beladen ist und f�hrt erst dann die Route ab. Wenn er auf seiner Route �ber eine Abkippstelle kommt h�lt er an und entleert seine(n) Anh�nger.			
				Man kann dem Abfahrer am Startpunkt allerdings auch sagen, dass er sofort abfahren soll.


			Typ: Kombiniert

				Der Kombinierte Modus ist �hnlich wie der Abfahrer Modus mit dem Unterschied, dass der Abfahrer am Startpunkt nicht wartet bis er beladen ist sondern selbstst�ndig zu einem Drescher oder H�cksler auf dem aktuellen Feld f�hrt und diese bedient.
				Wenn alle H�nger voll sind f�hrt der Abfahrer das zweite F�sschen auf seiner Route an und f�hrt von da an die Route ab wie der normale Abfahrer.
				Damit der kombinierte Modus funktioniert muss der Startpunkt des Abfahrers unbedingt auf dem gleichen Feld liegen auf dem der oder die Drescher sind.

			Typ: �berladewagen

				Beim Typ �berladewagen f�hrt der Abfahrer auch direkt zum Drescher oder H�cksler und f�hrt anschlie�end seine Route ab. Der Unterschied hierbei ist, dass der �berladewagen "Wartepunkte" als "Abladepunkte" nutzt.
				Wenn der �berladewagen also voll ist f�hrt er seine Route bis zum Wartepunkt ab und f�hrt dort automatisch weiter, wenn der �berladewagen leer ist.

			Typ: �berf�hrung

				In diesem Modus f�hrt der Abfahrer lediglich seine Route ab. Er wartet nicht am Startpunkt und wird an Abladestellen auch nicht entladen.
				Dieser Modus eignet sich in Verbindung mit Wartepunkten um Ger�tschaften zum Feld zu bringen oder zum Beispiel auch auf andere H�fe.

			Typ: D�ngen

				Im D�ngemodus f�llt der Abfahrhelfer am Startpunkt eine Spritze oder ein G�llefass und f�hrt dann seine Route ab. Man f�hrt mit dem Abfahrhelfer zum Feld, setzt einen Wartepunkt an der Stelle an der er mit dem D�ngen beginnen soll, f�hrt das Feld ab und setzt einen Wartepunkt am Feldende.
				Beim Abfahren klappt der Abfahrhelfer automatisch die Spritze/G�llefass aus und schaltet es an, f�hrt das Feld ab bis der Tank leer ist und f�hrt zur�ck zum auftanken. Nach dem Auftanken macht er an der Position weiter an der er aufgeh�rt hat.

			Typ: Feldarbeit (Ballenpressen, Schwadaufnahme)

				Der Feldarbeitsmodus funktioniert �hnlich wie der D�ngemodus. Hierbei wird ein zuvor aufgezeichneter Kurs mit Feldgeschwindigkeit abgefahren.
				Als Besonderheit kann man in diesem Modus zum Beispiel eine Ballenpresse anh�ngen. Die Rundballenpresse h�lt hierbei an wenn sie voll ist und wirft den Ballen aus.
				Wenn man einen Ladewagen anh�ngt wird der Kurs abgefahren bis dieser voll ist, dann wird die letzte Position gespeichert und der Kurs abgefahren. Der Kurs sollte dann nat�rlich an einem Abladetrigger vorbei f�hren. Dort wird der Wagen entleert und dann f�hrt er zur�ck zum Feld und setzt seine Arbeit am letzten Punkt fort.
				Der Arbeitsbereich des Modus Feldarbeit muss wie im D�ngemodus durch zwei Wartepunkte markiert werden.

		Wegpunkte l�schen:

			Wenn ein Kurs eingefahren ist kannst du �ber diese Option den Kurs wieder zur�cksetzen. Dabei wird der gespeicherte Kurs nicht aus der Konfigurationsdaten gel�scht sondern nur der aktuelle Abfahrer wieder zur�ckgesetzt.


	HUD Kurs speichern

		Im unteren Breich des Huds findet ihr eine Diskette. Wenn ihr einen Kurs eingefahren habt k�nnt ihr durch Klick auf die Diskette euren Kurs speichern.
		Dabei wird im oberen Bereich eine Eingabemaske angezeigt. Hier k�nnt ihr mit der Tastatur einen Namen f�r euren Kurs vergeben und diesen mit ENTER (Eingabetaste) best�tigen.

		Hinweis: Aktuell ist die Steuerung des Spiels im Speichermodus noch aktiv. Das hei�t wenn ihr zum Beispiel "e" dr�ckt steigt ihr leider noch aus dem Fahrzeug aus.
		In diesem Fall einfach wieder einsteigen und weiter tippen. Dieses Problem wird in einer sp�teren Version nat�rlich behoben.


	HUD "Kurse verwalten":

		Auf diser Unterseite des HUD findet ihr eine �bersicht eurer gespeicherten Kurse. Ihr k�nnt durch Klick auf das Ordner Symbol einen Kurs laden und durch einen Klick auf das rote X einen Kurs komplett l�schen.
		ACHTUNG: seit version 1.2 m�sst ihr wenn ihr einen neuen Kurs laden wollt erst die alten Wegpunkte zur�cksetzen, sonst kombiniert ihr die beiden Kurse!
		Mit den blauen Pfeilen rechts oben und rechts unten k�nnt ihr durch die gespeicherten Kurse bl�ttern.
		Hinweis zum Kombinieren von Kursen: Das Ordner Symbol ohne den blauen Pfeil kombiniert die Kurse am ersten gemeinsamen Kreuzungspunkt, der mit dem blauen Pfeil h�ngt die Kurse einfach hintereinander.

	HUD "Einstellungen Combi Modus":

		Diese Einstellungen gelten (wie der Name es andeutet) nur f�r den kombinierten Modus und den �berlademodus. Hiermit k�nnt ihr euren Abfahrer an den jeweiligen Drescher anpassen.
		Ihr k�nnt die Werte mit einem Klick auf das +/- Symbol daneben anpassen

		seitl. Abstand

			Dieser Wert definiert den seitlichen Abstand den ein Abfahrer zum Drescher oder H�cksler beim nebenher fahren einhalten soll.

		Start bei %:

			Dieser Wert legt fest ab welchem F�llstand des Dreschers der Abfahrer zu ihm f�hrt und ihn abtankt.
			Bei H�ckslern wird durch diesen Wert festgelegt ab wann der zweite Abfahrer in der Kette dem ersten hinterherfahren soll.

		Wenderadius:

			Dieser Wert ist nur beim H�ckseln wichtig und legt fest wie weit der Abfahrer beim Wenden des H�ckslers von ihm wegfahren soll ohne ihm im Weg zu stehen.

		Pipe Abstand:

			Dieser Wert legt fest wie weit der Abfahrer beim nebenher fahren vor oder zur�ck fahren soll. Hiermit l�sst sich der Abfahrer auf verschiedene Anh�nger umstellen.

	HUD "Drescher verwalten":

		Auch diese Einstellungen sind nur f�r den kombinierten Modus relevant. Hier k�nnt ihr einstellen ob der Abfahrer sich automatisch einen Drescher oder H�cksler suchen soll (Standard) oder er einen manuell zugewiesenen Drescher nutzen soll.
		Wenn ihr einen Drescher manuell zuweist muss dieser auch nicht auf dem gleichen Feld stehen. Der Abfahrer f�hrt von seinem Startpunkt automatisch zum Drescher, egal wo dieser sich befindet.

		Interessant ist diese Einstellung vor allem bei gro�en oder h�geligen Feldern auf denen die automatische Zuweisung nicht immer funktioniert und auf Feldern ohne Grubbertextur z.B. Wiesen.

	HUD "Geschwidigkeiten":	

		Hier k�nnt ihr festlegen wie schnell euer Abfahrer fahren soll. Ich denke mal die Einstellungen sind selbst erkl�rend ;)


IV. Credits
	Lautschreier/Wolverin0815/Bastian82/Hummel	

	Die Entwicklung von courseplay war wohl etwas "ungew�hnlich"

	Die Grundversion hat "lautschreier" Anfang des Jahres begonnen. Diese konnte bereits Kurse einspeichern und abfahren.
	Mitte Februar wurde ich (hummel/netjungle) auf dieses Projekt bei planet-ls.de aufmerksam und beschloss da etwas mitzuhelfen.
	Aus "etwas mithelfen" wurde eine krankhafte Sucht und das Ergebnis hei�t heute courseplay

	Ein besonderer Dank geht also selbstverst�nlich an Lautschreier ohne den dieses Projekt wohl nie gestartet w�re. Vor allem daf�r, dass er sein geistiges Eigentum zur Weiterentwicklung freigeben hat. (Open Source kann halt funktionieren)
	Weiterhin hat mich "Wolverin0815" auch sehr aktiv bei der Entwicklung unterst�tzt und unter anderem die erste Version des HUds integriert. Auch hier ein gro�er Dank f�r sein Engagement und seine Ideen.

	Den Feldarbeitsmodus mit automatischem Pressen und Schwadaufnahme mit einem Ladewagen verdanken wir bastian82

	Zudem geht nat�rlich ein riesengro�es Dankesch�n an alle die bei planet-ls.de flei�ig getestet haben und ihre Ideen haben einflie�en lassen. Die Enticklung hat mit soviel Feedback wirklich sehr viel Spa� gemacht.

	Auch beim Erfinder des Path Tractor aus LS 09 "micha381" an dem sich courseplay nat�rlich orientiert hat, muss ich mich bedanken.

	Ein dickes Dankesch�n auch an Sven777b, der mir die entscheidenen Tipps zum Thema Multiplayerf�higkeit gegeben hat.

	Und last but not least noch ein gro�es Dankesch�n an mein Weibchen die mich in den letzten Wochen diesen "24/7 Wahnsinn" hat ausleben lassen ;)

V. Videos

	Ich habe mir mal die M�he gemacht und einige Video-Tutorials zu Courseplay zur Verf�gung gestellt:

	Einbau:
	http://www.youtube.com/watch?v=frfNX5ZD090

	Steuerung/�berf�hrung
	http://www.youtube.com/watch?v=6ntt2RZGiTA

	Combi Modus
	http://www.youtube.com/watch?v=eQWQ7FrNBO8

	�berladewagen
	http://www.youtube.com/watch?v=DxyInzZgdDc

	D�ngemodus
	http://www.youtube.com/watch?v=7yvaOI_TUIg

	Feldmodus
	http://www.youtube.com/watch?v=fHnqo9Jq_nc
