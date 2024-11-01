<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
				<![CDATA[
					var debugFeed = [];
					var debugFlag = false; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{						
						var scenario = getScenario(jsonContext);
						var scenarioJPFlag = getJPFlagData(scenario);
						var scenarioMainGame = getMainGameData(scenario);
						var scenarioFeatureBonus = getFeatureBonusData(scenario);
						var scenarioJackpotBonus = getJackpotBonusData(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						const gridCols = 5;
						const gridRows = 3;

						var doFeatureBonus = (scenarioFeatureBonus.length == 5);
						var doJackpotBonus = (scenarioJPFlag == 'J');
						
						var arrGridData  = [];
						var arrAuditData = [];

						function getPhasesData(A_arrGridData, A_arrAuditData)
						{
							var arrClusters   = [];
							var arrPhaseCells = [];
							var arrPhases     = [];
							var objCluster    = {};
							var objPhase      = {};

							if (A_arrAuditData != '')
							{
								for (var phaseIndex = 0; phaseIndex < A_arrAuditData.length; phaseIndex++)
								{
									objPhase = {arrGrid: [], arrClusters: []};

									for (var colIndex = 0; colIndex < gridCols; colIndex++)
									{
										objPhase.arrGrid.push(A_arrGridData[colIndex].substr(0,gridRows));
									}

									arrClusters   = A_arrAuditData[phaseIndex].split(":");
									arrPhaseCells = [];

									for (var clusterIndex = 0; clusterIndex < arrClusters.length; clusterIndex++)
									{
										objCluster = {strPrefix: '', arrCells: []};

										objCluster.strPrefix = arrClusters[clusterIndex][0];

										objCluster.arrCells = arrClusters[clusterIndex].slice(1).match(new RegExp('.{1,2}', 'g')).map(function(item) {return parseInt(item,10);} );

										objPhase.arrClusters.push(objCluster);

										arrPhaseCells = arrPhaseCells.concat(objCluster.arrCells);
									}

									arrPhases.push(objPhase);

									arrPhaseCells.sort(function(a,b) {return b-a;} );

									for (var cellIndex = 0; cellIndex < arrPhaseCells.length; cellIndex++)
									{
										if (cellIndex == 0 || (cellIndex > 0 && arrPhaseCells[cellIndex] != arrPhaseCells[cellIndex-1]))
										{
											cellCol = Math.floor((arrPhaseCells[cellIndex]-1) / gridRows);
											cellRow = (arrPhaseCells[cellIndex]-1) % gridRows;

											if (cellCol >= 0 && cellCol < gridCols)
											{			
												A_arrGridData[cellCol] = A_arrGridData[cellCol].substring(0,cellRow) + A_arrGridData[cellCol].substring(cellRow+1);
											}
										}
									}
								}
							}

							objPhase = {arrGrid: [], arrClusters: []};

							for (var colIndex = 0; colIndex < gridCols; colIndex++)
							{
								objPhase.arrGrid.push(A_arrGridData[colIndex].substr(0,gridRows));
							}

							arrPhases.push(objPhase);

							return arrPhases;
						}

						arrGridData  = scenarioMainGame.split(":")[0].split(",");
						arrAuditData = scenarioMainGame.split(":").slice(1).join(":").split(",");

						var mgPhases = getPhasesData(arrGridData, arrAuditData);

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const symbPrizes       = 'ABCDEFG';
						const symbWild         = 'W';
						const symbFeatureBonus = 'Z';
						const symbSpecials     = symbFeatureBonus + symbWild;

						const cellSize      = 24;
						const cellWidthJB   = 60;
						const cellMargin    = 1;
						const cellTextX     = 13;
						const cellTextY     = 15;
						const colourBlack   = '#000000';
						const colourBlue    = '#99ccff';
						const colourGreen   = '#00cc00';
						const colourLemon   = '#ffff99';
						const colourLilac   = '#ccccff';
						const colourLime    = '#ccff99';
						const colourOrange  = '#ffcc99';
						const colourPurple  = '#cc99ff';
						const colourRed     = '#ff9999';
						const colourScarlet = '#ff0000';
						const colourWhite   = '#ffffff';
						const colourYellow  = '#ffff00';

						const prizeColours       = [colourRed, colourOrange, colourLemon, colourLime, colourBlue, colourLilac, colourPurple];
						const specialBoxColours  = [colourScarlet, colourBlack];
						const specialTextColours = [colourYellow, colourWhite];

						var r = [];

						var boxColourStr  = '';
						var canvasIdStr   = '';
						var elementStr    = '';
						var symbDesc      = '';
						var symbPrize     = '';
						var symbSpecial   = '';
						var textColourStr = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_cellWidth, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (A_cellWidth + 2 * cellMargin).toString() + '" height="' + (cellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_cellWidth.toString() + ', ' + cellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_cellWidth - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_cellWidth / 2 + cellMargin).toString() + ', ' + cellTextY.toString() + ');');

							r.push('</script>');
						}

						///////////////////////
						// Prize Symbols Key //
						///////////////////////

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titlePrizeSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var prizeIndex = 0; prizeIndex < symbPrizes.length; prizeIndex++)
						{
							symbPrize    = symbPrizes[prizeIndex];
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'eleKeySymb' + symbPrize;
							boxColourStr = prizeColours[prizeIndex];
							symbDesc     = 'symb' + symbPrize;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, cellSize, boxColourStr, colourBlack, symbPrize);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						/////////////////////////
						// Special Symbols Key //
						/////////////////////////

						r.push('<div style="float:left">');
						r.push('<p>' + getTranslationByName("titleSpecialSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var specialIndex = 0; specialIndex < symbSpecials.length; specialIndex++)
						{
							symbSpecial   = symbSpecials[specialIndex];
							canvasIdStr   = 'cvsKeySymb' + symbSpecial;
							elementStr    = 'eleKeySymb' + symbSpecial;
							boxColourStr  = specialBoxColours[specialIndex];
							textColourStr = specialTextColours[specialIndex];
							symbDesc      = 'symb' + symbSpecial;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, cellSize, boxColourStr, textColourStr, symbSpecial);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////

						const qtyFBTrigger = 3;

						var qtyFBSymbs       = 0;
						var countText        = '';
						var gridCanvasHeight = gridRows * cellSize + 2 * cellMargin;
						var gridCanvasWidth  = gridCols * cellSize + 2 * cellMargin;
						var isFBSymb         = false;
						var isCluster        = false;
						var phaseStr         = '';
						var prefixIndex      = -1;
						var prizeCount       = 0;
						var prizeStr         = '';
						var prizeText        = '';
						var triggerText      = '';

						function showGridSymbs(A_strCanvasId, A_strCanvasElement, A_arrGrid)
						{
							var canvasCtxStr  = 'canvasContext' + A_strCanvasElement;
							var cellX         = 0;
							var cellY         = 0;
							var isPrizeCell   = false;
							var isSpecialCell = false;
							var symbCell      = '';
							var symbIndex     = -1;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridCol = 0; gridCol < gridCols; gridCol++)
							{
								for (var gridRow = 0; gridRow < gridRows; gridRow++)
								{
									symbCell      = A_arrGrid[gridCol][gridRow];
									isPrizeCell   = (symbPrizes.indexOf(symbCell) != -1);
									isSpecialCell = (symbSpecials.indexOf(symbCell) != -1);
									symbIndex     = (isPrizeCell) ? symbPrizes.indexOf(symbCell) : ((isSpecialCell) ? symbSpecials.indexOf(symbCell) : -1);
									boxColourStr  = (isPrizeCell) ? prizeColours[symbIndex] : ((isSpecialCell) ? specialBoxColours[symbIndex] : colourBrown);
									textColourStr = (isPrizeCell) ? colourBlack : ((isSpecialCell) ? specialTextColours[symbIndex] : colourWhite);
									cellX         = gridCol * cellSize;
									cellY         = (gridRows - gridRow - 1) * cellSize;

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY).toString() + ');');
								}
							}

							r.push('</script>');
						}

						function showAuditSymbs(A_strCanvasId, A_strCanvasElement, A_arrGrid, A_arrData)
						{
							var canvasCtxStr  = 'canvasContext' + A_strCanvasElement;
							var cellX         = 0;
							var cellY         = 0;
							var isClusterCell = false;
							var isPrizeCell   = false;
							var isSpecialCell = false;
							var isWildCell    = false;
							var symbCell      = '';
							var symbIndex     = -1;
							var cellNum       = 0;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (gridCanvasWidth + 25).toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridCol = 0; gridCol < gridCols; gridCol++)
							{
								for (var gridRow = 0; gridRow < gridRows; gridRow++)
								{
									cellNum++;

									isClusterCell = (A_arrData.arrCells.indexOf(cellNum) != -1);
									isWildCell    = (isClusterCell && A_arrGrid[gridCol][gridRow] == symbWild);									
									symbCell      = ('0' + cellNum).slice(-2);
									isSpecialCell = (isWildCell || (isClusterCell && symbSpecials.indexOf(A_arrData.strPrefix) != -1));
									isPrizeCell   = (!isSpecialCell && isClusterCell && symbPrizes.indexOf(A_arrData.strPrefix) != -1);
									symbIndex     = (isPrizeCell) ? symbPrizes.indexOf(A_arrData.strPrefix) : ((isSpecialCell) ? ((isWildCell) ? symbSpecials.indexOf(symbWild) : symbSpecials.indexOf(A_arrData.strPrefix)) : -1);
									boxColourStr  = (isPrizeCell) ? prizeColours[symbIndex] : ((isSpecialCell) ? specialBoxColours[symbIndex] : colourWhite);
									textColourStr = (isPrizeCell) ? colourBlack : ((isSpecialCell) ? specialTextColours[symbIndex] : colourBlack);
									cellX         = gridCol * cellSize;
									cellY         = (gridRows - gridRow - 1) * cellSize;

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY).toString() + ');');
								}
							}

							r.push('</script>');
						}

						r.push('<p style="clear:both"><br>' + getTranslationByName("mainGame", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						for (var phaseIndex = 0; phaseIndex < mgPhases.length; phaseIndex++)
						{
							//////////////////////////
							// Main Game Phase Info //
							//////////////////////////

							phaseStr = getTranslationByName("phaseNum", translations) + ' ' + (phaseIndex+1).toString() + ' ' + getTranslationByName("phaseOf", translations) + ' ' + mgPhases.length.toString();

							r.push('<tr class="tablebody">');
							r.push('<td valign="top">' + phaseStr + '</td>');

							////////////////////
							// Main Game Grid //
							////////////////////

							canvasIdStr = 'cvsMainGrid' + phaseIndex.toString();
							elementStr  = 'eleMainGrid' + phaseIndex.toString();

							r.push('<td style="padding-left:50px; padding-right:50px; padding-bottom:25px">');

							showGridSymbs(canvasIdStr, elementStr, mgPhases[phaseIndex].arrGrid);

							r.push('</td>');

							/////////////////////////////////////////
							// Main Game Clusters or trigger cells //
							/////////////////////////////////////////

							r.push('<td style="padding-right:50px; padding-bottom:25px">');

							for (clusterIndex = 0; clusterIndex < mgPhases[phaseIndex].arrClusters.length; clusterIndex++)
							{
								canvasIdStr = 'cvsMainAudit' + phaseIndex.toString() + '_' + clusterIndex.toString();
								elementStr  = 'eleMainAudit' + phaseIndex.toString() + '_' + clusterIndex.toString();

								showAuditSymbs(canvasIdStr, elementStr, mgPhases[phaseIndex].arrGrid, mgPhases[phaseIndex].arrClusters[clusterIndex]);
							}

							r.push('</td>');

							//////////////////////////////////////
							// Main Game Prizes or trigger text //
							//////////////////////////////////////

							r.push('<td valign="top" style="padding-bottom:25px">');

							if (mgPhases[phaseIndex].arrClusters.length > 0)
							{
								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

								for (var clusterIndex = 0; clusterIndex < mgPhases[phaseIndex].arrClusters.length; clusterIndex++)
								{
									symbPrize     = mgPhases[phaseIndex].arrClusters[clusterIndex].strPrefix;
									isCluster     = (symbPrizes.indexOf(symbPrize) != -1);
									isFBSymb      = (symbPrize == symbFeatureBonus);
									canvasIdStr   = 'cvsMainClusterPrize' + phaseIndex.toString() + '_' + clusterIndex.toString() + symbPrize;
									elementStr    = 'eleMainClusterPrize' + phaseIndex.toString() + '_' + clusterIndex.toString() + symbPrize;
									prefixIndex   = (isCluster) ? symbPrizes.indexOf(symbPrize) : ((isFBSymb) ? symbSpecials.indexOf(symbPrize) : -1);
									boxColourStr  = (isCluster) ? prizeColours[prefixIndex] : ((isFBSymb) ? specialBoxColours[prefixIndex] : colourWhite);
									textColourStr = (isCluster) ? colourBlack : ((isFBSymb) ? specialTextColours[prefixIndex] : colourWhite);
									prizeCount    = mgPhases[phaseIndex].arrClusters[clusterIndex].arrCells.length;
									prizeText     = symbPrize + prizeCount.toString();									

									if (isFBSymb)
									{
										qtyFBSymbs += prizeCount;

										triggerText = (qtyFBSymbs == qtyFBTrigger) ? ' : ' + getTranslationByName("featureBonusTriggered", translations) : '';
									}

									countText = (isCluster || isFBSymb) ? prizeCount.toString() + ' x' : '';

									prizeStr  = (isCluster) ? '= ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)] : (
										        (isFBSymb) ? getTranslationByName("collected", translations) + ' ' + qtyFBSymbs.toString() + ' ' + getTranslationByName("phaseOf", translations) + ' ' + qtyFBTrigger.toString() + triggerText : '');

									r.push('<tr class="tablebody">');
									r.push('<td align="right">' + countText + '</td>');
									r.push('<td align="center">');

									showSymb(canvasIdStr, elementStr, cellSize, boxColourStr, textColourStr, symbPrize);
									
									r.push('</td>');
									r.push('<td>' + prizeStr + '</td>');
									r.push('</tr>');
								}

								r.push('</table>');
							}

							r.push('</td>');
							r.push('</tr>');
						}

						r.push('</table>'); 

						///////////////////
						// Feature Bonus //
						///////////////////

						if (doFeatureBonus)
						{
							const featureRounds = 5;

							var canvasIdStr2 = '';
							var elementStr2  = '';
							var featureMatch = false;
							var featureScore = 0;
							var featureText  = '';
							var roundScore   = 1;
							var roundText    = '';
							var scoreText    = '';
							var totalPrize   = '';
							var totalScore   = 0;

							r.push('<br><p>' + getTranslationByName("featureBonus", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							//////////////////////////
							// Feature Bonus Scores //
							//////////////////////////

							canvasIdStr  = 'cvsTitleFeature';
							elementStr   = 'eleTitleFeature';
							canvasIdStr2 = 'cvsTitleFeatureScore';
							elementStr2  = 'eleTitleFeatureScore';
							featureText  = getTranslationByName("titleFeatures", translations);
							scoreText    = getTranslationByName("titleFeatureScore", translations);

							r.push('<tr class="tablebody">');
							r.push('<td>&nbsp;</td>');
							r.push('<td>');

							showSymb(canvasIdStr, elementStr, 4 * cellSize, colourBlack, colourWhite, featureText);
								
							r.push('</td>');
							r.push('<td>');

							showSymb(canvasIdStr2, elementStr2, 3 * cellSize, colourBlack, colourWhite, scoreText);
								
							r.push('</td>');
							r.push('</tr>');

							for (roundIndex = 0; roundIndex < featureRounds; roundIndex++)
							{
								canvasIdStr = 'cvsTitleRound' + roundIndex.toString();
								elementStr  = 'eleTitleRound' + roundIndex.toString();
								roundText   = getTranslationByName("titleFeatureRound", translations) + ' ' + (roundIndex+1).toString();
								roundScore  = 1;

								r.push('<tr class="tablebody">');
								r.push('<td>');

								showSymb(canvasIdStr, elementStr, 4 * cellSize, colourBlack, colourWhite, roundText);
								
								r.push('</td>');
								r.push('<td align="center">');

								for (featureIndex = 0; featureIndex < 3; featureIndex++)
								{
									canvasIdStr  = 'cvsFeature' + roundIndex.toString() + '_' + featureIndex.toString();
									elementStr   = 'eleFeature' + roundIndex.toString() + '_' + featureIndex.toString();
									featureScore = featureIndex + 2;
									featureMatch = (scenarioFeatureBonus[roundIndex][featureIndex] == featureScore.toString());
									boxColourStr = (featureMatch) ? colourGreen : colourWhite;
									roundScore   *= (featureMatch) ? featureScore : 1;

									showSymb(canvasIdStr, elementStr, cellSize, boxColourStr, colourBlack, featureScore.toString());
								}

								roundScore = (roundScore == 1) ? 0 : roundScore;
								totalScore += roundScore;

								r.push('</td>');

								canvasIdStr = 'cvsScore' + roundIndex.toString();
								elementStr  = 'eleScore' + roundIndex.toString();

								r.push('<td>');

								showSymb(canvasIdStr, elementStr, 3 * cellSize, colourWhite, colourBlack, roundScore.toString());
								
								r.push('</td>');
								r.push('</tr>');
							}

							r.push('</table>');

							prizeText = 'M' + totalScore.toString();

							totalPrize = getTranslationByName("featureTotalScore", translations) + ' = ' + totalScore.toString() + ' ' + getTranslationByName("featurePoints", translations);
							totalPrize += ' : ' + getTranslationByName("featureWins", translations) + ' ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)];

							r.push('<br><p>' + totalPrize + '</p>');
						}

						///////////////////
						// Jackpot Bonus //
						///////////////////

						if (doJackpotBonus)
						{
							const jackpotLevels = 5;

							var isJPSymb    = false;
							var jackpotText = '';
							var jackpotWin  = '';
							var jpCount     = 0;
							var turnText    = '';

							r.push('<br><p>' + getTranslationByName("jackpotBonus", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							/////////////////////////
							// Jackpot Bonus Turns //
							/////////////////////////

							r.push('<tr class="tablebody">');
							r.push('<td>&nbsp;</td>');

							for (var turnIndex = 0; turnIndex < scenarioJackpotBonus.length; turnIndex++)
							{
								canvasIdStr = 'cvsTitleJBTurn' + turnIndex.toString();
								elementStr  = 'eleTitleJBTurn' + turnIndex.toString();
								turnText    = getTranslationByName("titleJBTurn", translations) + ' ' + (turnIndex+1).toString();

								r.push('<td>');

								showSymb(canvasIdStr, elementStr, cellWidthJB, colourBlack, colourWhite, turnText);

								r.push('</td>');
							}

							r.push('</tr>');

							for (var jackpotIndex = 0; jackpotIndex < jackpotLevels; jackpotIndex++)
							{
								canvasIdStr = 'cvsTitleJackpot' + jackpotIndex.toString();
								elementStr  = 'eleTitleJackpot' + jackpotIndex.toString();
								jackpotText = getTranslationByName("titleJackpot", translations) + ' ' + (jackpotIndex+1).toString();
								jpCount     = 0;

								r.push('<tr class="tablebody">');
								r.push('<td>');

								showSymb(canvasIdStr, elementStr, 2 * cellWidthJB, colourBlack, colourWhite, jackpotText);
								
								r.push('</td>');

								for (var turnIndex = 0; turnIndex < scenarioJackpotBonus.length; turnIndex++)
								{
									canvasIdStr   = 'cvsJackpotBonus' + jackpotIndex.toString() + '_' + turnIndex.toString();
									elementStr    = 'eleJackpotBonus' + jackpotIndex.toString() + '_' + turnIndex.toString();
									isJPSymb      = (scenarioJackpotBonus[turnIndex] == (jackpotIndex+1).toString());
									jpCount       += (isJPSymb) ? 1 : 0;
									boxColourStr  = (jpCount == 3) ? colourScarlet : ((isJPSymb) ? colourOrange : colourWhite);
									textColourStr = (jpCount == 3) ? colourYellow : colourBlack;

									r.push('<td>');

									showSymb(canvasIdStr, elementStr, cellWidthJB, boxColourStr, textColourStr, jpCount.toString());

									r.push('</td>');
								}

								if (jpCount == 3)
								{
									jackpotWin = getTranslationByName("jackpotWins", translations) + ' ' + getTranslationByName("titleJackpot", translations).toUpperCase() + ' ' + (jackpotIndex+1).toString();

									r.push('<td>' + jackpotWin + '</td>');
								}

								r.push('</tr>');
							}

							r.push('</table>');
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
	 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
 								r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getJPFlagData(scenario)
					{
						return scenario.split("|")[0];
					}

					function getMainGameData(scenario)
					{
						return scenario.split("|")[1];
					}

					function getFeatureBonusData(scenario)
					{
						return scenario.split("|")[2].split(",");
					}

					function getJackpotBonusData(scenario)
					{
						return scenario.split("|")[3];
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;
						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
				]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="SignedData/Data/Outcome/ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			

				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>				
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
						<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
