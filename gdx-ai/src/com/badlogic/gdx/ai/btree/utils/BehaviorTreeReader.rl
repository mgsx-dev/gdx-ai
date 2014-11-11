// Do not edit this file! Generated by Ragel.
// Ragel.exe -G2 -J -o BehaviorTreeReader.java BehaviorTreeReader.rl
/*******************************************************************************
 * Copyright 2014 See AUTHORS file.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

package com.badlogic.gdx.ai.btree.utils;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;

import com.badlogic.gdx.ai.btree.BehaviorTree;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.GdxRuntimeException;
import com.badlogic.gdx.utils.SerializationException;
import com.badlogic.gdx.utils.StreamUtils;

/** An abstract event driven {@link BehaviorTree} parser.
 * 
 * @author davebaol */
public abstract class BehaviorTreeReader {

	public boolean debug = false;
	protected int lineNumber;

	protected abstract void startStatement (int indent, String name);

	protected abstract void attribute (String name, Object value);

	protected abstract void endStatement ();

	/** Parses the given string.
	 * @param string the string
	 * @throws SerializationException if the string cannot be successfully parsed. */
	public void parse (String string) {
		char[] data = string.toCharArray();
		parse(data, 0, data.length);
	}

	/** Parses the given reader.
	 * @param reader the reader
	 * @throws SerializationException if the reader cannot be successfully parsed. */
	public void parse (Reader reader) {
		try {
			char[] data = new char[1024];
			int offset = 0;
			while (true) {
				int length = reader.read(data, offset, data.length - offset);
				if (length == -1) break;
				if (length == 0) {
					char[] newData = new char[data.length * 2];
					System.arraycopy(data, 0, newData, 0, data.length);
					data = newData;
				} else
					offset += length;
			}
			parse(data, 0, offset);
		} catch (IOException ex) {
			throw new SerializationException(ex);
		} finally {
			StreamUtils.closeQuietly(reader);
		}
	}

	/** Parses the given input stream.
	 * @param input the input stream
	 * @throws SerializationException if the input stream cannot be successfully parsed. */
	public void parse (InputStream input) {
		try {
			parse(new InputStreamReader(input, "UTF-8"));
		} catch (IOException ex) {
			throw new SerializationException(ex);
		} finally {
			StreamUtils.closeQuietly(input);
		}
	}

	/** Parses the given file.
	 * @param file the file
	 * @throws SerializationException if the file cannot be successfully parsed. */
	public void parse (FileHandle file) {
		try {
			parse(file.reader("UTF-8"));
		} catch (Exception ex) {
			throw new SerializationException("Error parsing file: " + file, ex);
		}
	}

	/** Parses the given data buffer from the offset up to the specified number of characters.
	 * @param data the buffer
	 * @param offset the initial index
	 * @param length the specified number of characters to parse.
	 * @throws SerializationException if the buffer cannot be successfully parsed. */
	public void parse (char[] data, int offset, int length) {
		int cs, p = offset, pe = length, eof = pe;

		int s = 0;
		int indent = 0;
		String statementName = null;
		boolean taskProcessed = false;
		boolean needsUnescape = false;
		boolean stringIsUnquoted = false;
		RuntimeException parseRuntimeEx = null;
		String attrName = null;

		lineNumber = 1;

		if (debug) System.out.println();

		try {
		%%{
			machine btree;

			action attrValue {
				String value = new String(data, s, p - s);
				s = p;
				if (needsUnescape) value = unescape(value);
				outer:
				if (stringIsUnquoted) {
					if (debug) System.out.println("string: " + attrName + "=" + value);
					if (value.equals("true")) {
						if (debug) System.out.println("boolean: " + attrName + "=true");
						attribute(attrName, Boolean.TRUE);
						break outer;
					} else if (value.equals("false")) {
						if (debug) System.out.println("boolean: " + attrName + "=false");
						attribute(attrName, Boolean.FALSE);
						break outer;
					} else if (value.equals("null")) {
						attribute(attrName, null);
						break outer;
					} else { // number
						try {
							if (value.indexOf('.') != -1) {
								if (debug) System.out.println("double: " + attrName + "=" + Double.parseDouble(value));
								attribute(attrName, new Double(value));
								break outer;
							} else {
								if (debug) System.out.println("double: " + attrName + "=" + Double.parseDouble(value));
								attribute(attrName, new Long(value));
								break outer;
							}
						} catch (NumberFormatException nfe) {
							throw new GdxRuntimeException("Attribute value must be a number, a boolean, a string or null");
						}
					}
				}
				else {
					if (debug) System.out.println("string: " + attrName + "=\"" + value + "\"");
					attribute(attrName, value);
				}
				stringIsUnquoted = false;
			}
			action unquotedChars {
				if (debug) System.out.println("unquotedChars");
				s = p;
				needsUnescape = false;
				stringIsUnquoted = true;
				outer:
				while (true) {
					switch (data[p]) {
					case '\\':
						needsUnescape = true;
						break;
					case ' ':
					case '\r':
					case '\n':
					case '\t':
						break outer;
					}
					// if (debug) System.out.println("unquotedChar (value): '" + data[p] + "'");
					p++;
					if (p == eof) break;
				}
				p--;
			}
			action quotedChars {
				if (debug) System.out.println("quotedChars");
				s = ++p;
				needsUnescape = false;
				outer:
				while (true) {
					switch (data[p]) {
					case '\\':
						needsUnescape = true;
						p++;
						break;
					case '"':
						break outer;
					}
					// if (debug) System.out.println("quotedChar: '" + data[p] + "'");
					p++;
					if (p == eof) break;
				}
				p--;
			}
			action newLine {
				indent = 0;
				statementName = null;
				taskProcessed = false;
				lineNumber++;
				if (debug) System.out.println("****NEWLINE**** "+lineNumber);
			}
			action indent {
				indent++;
			}
			action endLine {
				taskProcessed = true;
				if (statementName != null)
					endStatement();
				if (debug) System.out.println("endLine: indent: " + indent + " taskName: " + statementName + " data[" + p + "] = " + (p >= eof ? "EOF" : "\"" + data[p] + "\""));
			}
			action comment {
				if (debug) System.out.println("# Comment");
			}
			action taskName {
				s = p;
				char c;
				do {
					if (++p == eof) break;
					c = data[p];
				} while ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
							|| c == '.'  || c == '_'  || c == '?');
				statementName = new String(data, s, p - s);
				p--;
				startStatement(indent, statementName);
			}
			action attrName {
				s = p;
				char c;
				do {
					if (++p == eof) break;
					c = data[p];
				} while ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
							|| c == '_' || c == '?');
				attrName = new String(data, s, p - s);
				p--;
			}

			ws = [ \r\t];
			nl = '\n' @newLine;
			comment = '#' /[^\n]*/ %comment;
			indent = [ \t] @indent;
			attrName = [a-zA-Z_] @attrName;
			attrValue = '"' @quotedChars %attrValue '"' | ^[#:"\r\n\t ] >unquotedChars %attrValue;
			attribute = attrName ws* ':' ws* attrValue;
			attributes = (ws+ attribute)+;
			taskName = [a-zA-Z_] @taskName;
			task = taskName attributes?;
			line = indent* task? ws* comment? %endLine;
			main := line (nl line)** nl?;


			write init;
			write exec;
		}%%
		} catch (RuntimeException ex) {
			parseRuntimeEx = ex;
		}

		if (p < pe || (statementName != null && !taskProcessed)) {
			throw new SerializationException("Error parsing behavior tree on line " + lineNumber + " near: " + new String(data, p, pe - p),
				parseRuntimeEx);
		} else if (parseRuntimeEx != null) {
			throw new SerializationException("Error parsing behavior tree: " + new String(data), parseRuntimeEx);
		}
	}

	%% write data;

	private String unescape (String value) {
		int length = value.length();
		StringBuilder buffer = new StringBuilder(length + 16);
		for (int i = 0; i < length;) {
			char c = value.charAt(i++);
			if (c != '\\') {
				buffer.append(c);
				continue;
			}
			if (i == length) break;
			c = value.charAt(i++);
			if (c == 'u') {
				buffer.append(Character.toChars(Integer.parseInt(value.substring(i, i + 4), 16)));
				i += 4;
				continue;
			}
			switch (c) {
			case '"':
			case '\\':
			case '/':
				break;
			case 'b':
				c = '\b';
				break;
			case 'f':
				c = '\f';
				break;
			case 'n':
				c = '\n';
				break;
			case 'r':
				c = '\r';
				break;
			case 't':
				c = '\t';
				break;
			default:
				throw new SerializationException("Illegal escaped character: \\" + c);
			}
			buffer.append(c);
		}
		return buffer.toString();
	}
}