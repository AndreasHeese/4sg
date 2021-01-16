<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright 2016-2017 - 4sg.xsl - Small and Simple SVG Sankey Generator - Andreas Heese - Version 0.2 - MIT-License -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://heese.net" xmlns="http://www.w3.org/2000/svg" exclude-result-prefixes="fn">
	<xsl:output method="xml" indent="yes" media-type="image/svg"/>
	<xsl:variable name="width" select="/root/piles/pile[1]/@left + /root/piles/pile[last()]/@left + /root/piles/pile[last()]/@width"/>
	<xsl:variable name="flows" select="/root/flows"/>
	<xsl:variable name="piles" select="/root/piles"/>
	<xsl:function name="fn:boxheight">
		<xsl:param name="id"/>
		<xsl:sequence select="max((sum($flows/flow[@to = $id]/@value), sum($flows/flow[@from = $id]/@value)))"/>
	</xsl:function>
	<xsl:function name="fn:pileheight">
		<xsl:param name="p"/>
		<xsl:variable name="r1" select="sum(for $b in $p/box return sum(fn:boxheight($b/@id)))"/>
		<xsl:variable name="r2" select="$p/@top + sum($p/box/ancestor-or-self::*[@gap][1]/@gap)"/>
		<xsl:variable name="r4" select="$r1 + $r2"/>
		<xsl:sequence select="$r4"/>
	</xsl:function>
	<xsl:function name="fn:piles">
		<xsl:sequence select="for $p in $piles/pile return fn:pileheight($p)"/>
	</xsl:function>
	<xsl:template match="root">
		<xsl:variable name="height" select="max(fn:piles())"/>
		<xsl:comment> Generated with 4sg.xsl - Small and Simple SVG Sankey Generator - Andreas Heese </xsl:comment>
		<svg viewBox="0 0 {$width} {$height + 10}" preserveAspectRatio="xMidYMin meet">
			<title><xsl:value-of select="title[1]"/></title>
			<xsl:apply-templates select="piles/pile/box, piles/pile/title, title"/>
		</svg>
	</xsl:template>
	<xsl:template match="title">
		<text x="{if (parent::pile) then (parent::pile/@left + (parent::pile/@width div 2)) else ($width div 2)}" y="{if (parent::pile) then (parent::pile/@top - 2) else (10)}" style="font-family:{ancestor-or-self::*[@font-family][1]/@font-family}; font-size:{ancestor-or-self::*[@font-size][1]/@font-size}; fill:black; text-anchor:middle;" dominant-baseline="{if (parent::pile) then ('ideographic') else ('hanging')}"><xsl:value-of select="."/></text>
	</xsl:template>
	<xsl:template match="box">
		<xsl:variable name="this" select="@id"/>
		<xsl:variable name="ytrace" select="sum(for $b in preceding-sibling::box return fn:boxheight($b/@id))"/>
		<xsl:variable name="gapsum" select="sum(for $b in (self::box|preceding-sibling::box)[preceding-sibling::box] return $b/ancestor-or-self::*[@gap][1]/@gap)"/>
		<xsl:variable name="y" select="../@top + $gapsum + $ytrace"/>
		<xsl:variable name="height" select="fn:boxheight($this)"/>
		<xsl:apply-templates select="/root/flows/flow[@from = $this]"/>
		<rect x="{../@left}" y="{$y}" width="{ancestor-or-self::*[@width][1]/@width}" height="{$height}" style="fill:{ancestor-or-self::*[@color][1]/@color}"/>
		<xsl:if test="text()">
			<text x="{../@left + ancestor-or-self::*[@width][1]/@width div 2}" y="{$y + $height div 2}" style="font-family:{ancestor::*[@font-family][1]/@font-family}; font-size:{ancestor::*[@font-size][1]/@font-size}; fill:black; text-anchor:middle;" dominant-baseline="central">
				<xsl:value-of select="."/>
			</text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="flow">
		<xsl:variable name="from" select="@from"/>
		<xsl:variable name="to" select="@to"/>
		<xsl:variable name="lx" select="/root/piles/pile[box/@id = $from]/@left + /root/piles/pile/box[@id = $from]/ancestor-or-self::*[@width][1]/@width"/>
		<xsl:variable name="rx" select="/root/piles/pile[box/@id = $to]/@left"/>
		<xsl:variable name="ytracefrom" select="sum(for $b in /root/piles/pile/box[@id = $from]/preceding-sibling::box return fn:boxheight($b/@id))"/>
		<xsl:variable name="ytraceto" select="sum(for $b in /root/piles/pile/box[@id = $to]/preceding-sibling::box return fn:boxheight($b/@id))"/>
		<xsl:variable name="ygapfrom" select="sum(for $b in (/root/piles/pile/box[@id = $from]|/root/piles/pile/box[@id = $from]/preceding-sibling::box)[preceding-sibling::box] return $b/ancestor-or-self::*[@gap][1]/@gap)"/>
		<xsl:variable name="ygapto" select="sum(for $b in (/root/piles/pile/box[@id = $to]|/root/piles/pile/box[@id = $to]/preceding-sibling::box)[preceding-sibling::box] return $b/ancestor-or-self::*[@gap][1]/@gap)"/>
		<xsl:variable name="ly" select="/root/piles/pile[box/@id = $from]/@top + $ygapfrom + $ytracefrom + sum(preceding-sibling::flow[@from = $from]/@value) + (@value div 2)"/>
		<xsl:variable name="ry" select="/root/piles/pile[box/@id = $to]/@top + $ygapto + $ytraceto + sum(preceding-sibling::flow[@to = $to]/@value) + (@value div 2)"/>
		<path d="M {$lx},{$ly} L {$lx + 1},{$ly} C {$lx + ../@bend},{$ly} {$rx - ../@bend},{$ry} {$rx - 1},{$ry} L {$rx},{$ry}" style="stroke:{ancestor-or-self::*[@color][1]/@color}; stroke-width:{@value}; fill:none; stroke-opacity:{../@opacity}; stroke-linejoin:round;"/>
	</xsl:template>
</xsl:stylesheet>
