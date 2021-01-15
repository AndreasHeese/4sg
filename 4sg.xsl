<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright 2016 - 4sg.xsl - Small and Simple SVG Sankey Generator - Andreas Heese - Version 0.1 - MIT-License -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2000/svg">
	<xsl:variable name="width" select="/root/piles/pile[1]/@left + /root/piles/pile[last()]/@left + /root/piles/pile[last()]/@width"/>
	<xsl:variable name="height">
		<xsl:apply-templates select="/root/piles/pile[last()]" mode="trace"/>
	</xsl:variable>	
	<xsl:template match="root">
		<xsl:comment> Generated with 4sg.xsl - Small and Simple SVG Sankey Generator - Andreas Heese </xsl:comment>
		<svg viewBox="0 0 {$width} {$height + 10}" preserveAspectRatio="xMidYMin meet">
			<title><xsl:value-of select="title[1]"/></title>
			<xsl:apply-templates select="piles/pile/box"/>
			<text x="{$width div 2}" y="10" style="font-family:{ancestor-or-self::*[@font-family][1]/@font-family}; font-size:{ancestor-or-self::*[@font-size][1]/@font-size}; fill:black; text-anchor:middle;" dominant-baseline="hanging"><xsl:value-of select="title[1]"/></text>
		</svg>
	</xsl:template>
	<xsl:template match="box">
		<xsl:variable name="this" select="@id"/>
		<xsl:variable name="ytrace">
			<xsl:apply-templates select="preceding-sibling::box[1]" mode="trace"/>
			<xsl:if test="not(preceding-sibling::box[1])">
				<xsl:value-of select="0"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="y" select="../@top + (count(preceding-sibling::box) * /root/piles/@gap) + $ytrace"/>
		<xsl:variable name="hfrom" select="sum(/root/flows/flow[@from = $this]/@value)"/>
		<xsl:variable name="hto" select="sum(/root/flows/flow[@to = $this]/@value)"/>
		<xsl:variable name="height" select="($hfrom >= $hto) * $hfrom + ($hto > $hfrom) * $hto"/>
		<xsl:apply-templates select="/root/flows/flow[@from = $this]"/>
		<rect x="{../@left}" y="{$y}" width="{../@width}" height="{$height}" style="fill:{ancestor-or-self::*[@color][1]/@color}"/>
		<xsl:if test="text()">
			<text x="{../@left + ../@width div 2}" y="{$y + $height div 2}" style="font-family:{ancestor::*[@font-family][1]/@font-family}; font-size:{ancestor::*[@font-size][1]/@font-size}; fill:black; text-anchor:middle;" dominant-baseline="central"><xsl:value-of select="."/></text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="pile" mode="trace">
		<xsl:param name="lastsum" select="0"/>
		<xsl:variable name="currsum1">
			<xsl:apply-templates select="box[last()]" mode="trace"/>
		</xsl:variable>
		<xsl:variable name="currsum2" select="@top + (count(box) * /root/piles/@gap) + $currsum1 "/>
		<xsl:variable name="newsum" select="($lastsum >= $currsum2) * $lastsum + ($currsum2 > $lastsum) * $currsum2"/>
		<xsl:apply-templates select="preceding-sibling::pile[1]" mode="trace">
			<xsl:with-param name="lastsum" select="$newsum"/>
		</xsl:apply-templates>
		<xsl:if test="not(preceding-sibling::pile)">
			<xsl:value-of select="$newsum"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="box" mode="trace">
		<xsl:param name="p" select="0"/>
		<xsl:variable name="this" select="@id"/>
		<xsl:variable name="yfrom" select="sum(/root/flows/flow[@from = $this]/@value)"/>
		<xsl:variable name="yto" select="sum(/root/flows/flow[@to = $this]/@value)"/>
		<xsl:variable name="y" select="($yfrom >= $yto) * $yfrom + ($yto > $yfrom) * $yto"/>
		<xsl:apply-templates select="preceding-sibling::box[1]" mode="trace">
			<xsl:with-param name="p" select="$p + $y"/>
		</xsl:apply-templates>
		<xsl:if test="not(preceding-sibling::box)">
			<xsl:value-of select="$p + $y"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="flow">
		<xsl:variable name="from" select="@from"/>
		<xsl:variable name="to" select="@to"/>
		<xsl:variable name="lx" select="/root/piles/pile[box/@id = $from]/@left + /root/piles/pile[box/@id = $from]/@width"/>
		<xsl:variable name="rx" select="/root/piles/pile[box/@id = $to]/@left"/>
		<xsl:variable name="ytracefrom">
			<xsl:apply-templates select="/root/piles/pile/box[@id = $from]/preceding-sibling::box[1]" mode="trace"/>
			<xsl:if test="not(/root/piles/pile/box[@id = $from]/preceding-sibling::box[1])">
				<xsl:value-of select="0"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="ytraceto">
			<xsl:apply-templates select="/root/piles/pile/box[@id = $to]/preceding-sibling::box[1]" mode="trace"/>
			<xsl:if test="not(/root/piles/pile/box[@id = $to]/preceding-sibling::box[1])">
				<xsl:value-of select="0"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="yfrom" select="/root/piles/pile[box/@id = $from]/@top + (count(/root/piles/pile/box[@id = $from]/preceding-sibling::box) * /root/piles/@gap) + $ytracefrom"/>
		<xsl:variable name="yto" select="/root/piles/pile[box/@id = $to]/@top + (count(/root/piles/pile/box[@id = $to]/preceding-sibling::box) * /root/piles/@gap) + $ytraceto"/>
		<xsl:variable name="ly" select="$yfrom + sum(preceding-sibling::flow[@from = $from]/@value) + (@value div 2)"/>
		<xsl:variable name="ry" select="$yto + sum(preceding-sibling::flow[@to = $to]/@value) + (@value div 2)"/>
		<path d="M {$lx},{$ly} L {$lx + 1},{$ly} C {$lx + ../@bend},{$ly} {$rx - ../@bend},{$ry} {$rx - 1},{$ry} L {$rx},{$ry}" style="stroke:{ancestor-or-self::*[@color][1]/@color}; stroke-width:{@value}; fill:none; stroke-opacity:{../@opacity}; stroke-linejoin:round;"/>
	</xsl:template>
</xsl:stylesheet>
